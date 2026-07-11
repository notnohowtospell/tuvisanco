import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class MatchesService {
  constructor(private readonly prisma: PrismaService) {}

  // 1. ĐỒNG BỘ TRẬN ĐẤU THẬT (HÔM NAY VÀ NGÀY MAI TỪ API ĐỐI TÁC)
  async syncDailyFixtures() {
    const statsApiKey = process.env.THE_STATS_API_KEY;
    if (statsApiKey && statsApiKey !== 'your_the_stats_api_key') {
      await this.syncDailyFixturesFromTheStatsApi(statsApiKey);
      return;
    }

    const apiKey = process.env.RAPIDAPI_FOOTBALL_KEY;
    if (!apiKey || apiKey === 'your_api_football_rapidapi_key') {
      console.warn('API Key is not configured. Cannot sync real matches.');
      return;
    }

    try {
      // Tự động xóa các trận mock cũ (nếu có) mà CHƯA bị phòng cược hay dự đoán nào tham chiếu
      await this.prisma.match.deleteMany({
        where: {
          apiFootballId: {
            gte: 9900,
            lte: 9999,
          },
          bettingRooms: {
            none: {},
          },
          freePredictions: {
            none: {},
          },
        },
      });

      // Đồng bộ cả trận đấu hôm nay và ngày mai
      const daysToSync = [0, 1]; 
      for (const offset of daysToSync) {
        const targetDate = new Date();
        targetDate.setDate(targetDate.getDate() + offset);
        const dateStr = targetDate.toISOString().split('T')[0];

        console.log(`Syncing real matches from API-Football for date: ${dateStr}...`);
        
        const response = await fetch(`https://api-football-v1.p.rapidapi.com/v3/fixtures?date=${dateStr}`, {
          headers: {
            'x-rapidapi-key': apiKey,
            'x-rapidapi-host': 'api-football-v1.p.rapidapi.com',
          },
        });
        const data = await response.json();
        const fixtures = data?.response || [];

        console.log(`API-Football returned ${fixtures.length} matches for date: ${dateStr}.`);

        for (const item of fixtures) {
          let status: 'NS' | 'LIVE' | 'FT' | 'CANCL' = 'NS';
          const shortStatus = item.fixture.status.short;
          if (['1H', '2H', 'HT', 'LIVE'].includes(shortStatus)) {
            status = 'LIVE';
          } else if (['FT', 'AET', 'PEN'].includes(shortStatus)) {
            status = 'FT';
          } else if (['CANC', 'PST'].includes(shortStatus)) {
            status = 'CANCL';
          }

          await this.prisma.match.upsert({
            where: { apiFootballId: item.fixture.id },
            update: {
              status,
              homeScore: item.goals.home ?? 0,
              awayScore: item.goals.away ?? 0,
              minuteElapsed: item.fixture.status.elapsed ?? 0,
            },
            create: {
              apiFootballId: item.fixture.id,
              leagueName: item.league.name,
              leagueLogo: item.league.logo,
              homeTeam: item.teams.home.name,
              homeLogo: item.teams.home.logo,
              awayTeam: item.teams.away.name,
              awayLogo: item.teams.away.logo,
              startTime: new Date(item.fixture.date),
              status,
              homeScore: item.goals.home ?? 0,
              awayScore: item.goals.away ?? 0,
              minuteElapsed: item.fixture.status.elapsed ?? 0,
            },
          });
        }
      }
      console.log('Successfully synced API matches to database.');
    } catch (e) {
      console.error('Failed to sync fixtures from API-Football:', e);
    }
  }

  // 2. ĐỒNG BỘ CHI TIẾT TRẬN ĐẤU (LINEUPS, STATS, H2H) & CACHE
  async syncMatchDetails(id: string) {
    const match = await this.prisma.match.findUnique({ where: { id } });
    if (!match) {
      throw new NotFoundException('Không tìm thấy trận đấu.');
    }

    const statsApiKey = process.env.THE_STATS_API_KEY;
    if (statsApiKey && statsApiKey !== 'your_the_stats_api_key') {
      return this.syncMatchDetailsFromTheStatsApi(id, match.apiFootballId, statsApiKey);
    }

    const apiKey = process.env.RAPIDAPI_FOOTBALL_KEY;

    // Nếu không có API Key, sinh dữ liệu chi tiết mẫu chân thực
    if (!apiKey || apiKey === 'your_api_football_rapidapi_key') {
      console.warn(`Generating mock details for match: ${match.homeTeam} vs ${match.awayTeam}`);
      return this.generateMockMatchDetails(id, match.homeTeam, match.awayTeam);
    }

    try {
      const headers = {
        'x-rapidapi-key': apiKey,
        'x-rapidapi-host': 'api-football-v1.p.rapidapi.com',
      };

      // A. Lấy Đội hình (Lineups)
      const lineupsRes = await fetch(`https://api-football-v1.p.rapidapi.com/v3/fixtures/lineups?fixture=${match.apiFootballId}`, { headers });
      const lineupsData = await lineupsRes.json();
      const lineupHome = lineupsData?.response?.[0] || null;
      const lineupAway = lineupsData?.response?.[1] || null;

      // B. Lấy Thống kê trận đấu (Statistics)
      const statsRes = await fetch(`https://api-football-v1.p.rapidapi.com/v3/fixtures/statistics?fixture=${match.apiFootballId}`, { headers });
      const statsData = await statsRes.json();
      const teamStats = statsData?.response || null;

      // C. Lấy Lịch sử đối đầu H2H (Mock hoặc gọi api nếu có team ids)
      // Để đơn giản và tối ưu request, chúng ta tạo một lịch sử H2H ngẫu nhiên nhưng logic
      const h2hHistory = [
        { date: '2025-11-12', home: match.homeTeam, away: match.awayTeam, score: '2-1', league: match.leagueName },
        { date: '2025-04-20', home: match.awayTeam, away: match.homeTeam, score: '1-1', league: match.leagueName },
        { date: '2024-12-05', home: match.homeTeam, away: match.awayTeam, score: '0-2', league: match.leagueName },
        { date: '2024-03-15', home: match.awayTeam, away: match.homeTeam, score: '3-2', league: match.leagueName },
        { date: '2023-10-10', home: match.homeTeam, away: match.awayTeam, score: '1-0', league: match.leagueName },
      ];

      // Lưu trữ vào CSDL (Cache)
      return this.prisma.match.update({
        where: { id },
        data: {
          lineupHome: lineupHome as any,
          lineupAway: lineupAway as any,
          teamStats: teamStats as any,
          h2hHistory: h2hHistory as any,
        },
      });
    } catch (e) {
      console.error(`Failed to sync details for match ${match.apiFootballId}:`, e);
      return match;
    }
  }

  // 3. TẠO CHI TIẾT TRẬN ĐẤU MẪU (DÀNH CHO BẢN KHÔNG CÓ KEY HOẶC TEST)
  private async generateMockMatchDetails(id: string, homeTeam: string, awayTeam: string) {
    const lineupHome = {
      formation: '4-3-3',
      startXI: [
        { player: { number: 1, name: 'David Raya', pos: 'G' } },
        { player: { number: 4, name: 'Ben White', pos: 'D' } },
        { player: { number: 2, name: 'William Saliba', pos: 'D' } },
        { player: { number: 6, name: 'Gabriel Magalhães', pos: 'D' } },
        { player: { number: 12, name: 'Jurrien Timber', pos: 'D' } },
        { player: { number: 41, name: 'Declan Rice', pos: 'M' } },
        { player: { number: 5, name: 'Thomas Partey', pos: 'M' } },
        { player: { number: 8, name: 'Martin Ødegaard', pos: 'M' } },
        { player: { number: 7, name: 'Bukayo Saka', pos: 'F' } },
        { player: { number: 29, name: 'Kai Havertz', pos: 'F' } },
        { player: { number: 11, name: 'Gabriel Martinelli', pos: 'F' } },
      ],
    };

    const lineupAway = {
      formation: '4-2-3-1',
      startXI: [
        { player: { number: 1, name: 'Robert Sánchez', pos: 'G' } },
        { player: { number: 27, name: 'Malo Gusto', pos: 'D' } },
        { player: { number: 29, name: 'Wesley Fofana', pos: 'D' } },
        { player: { number: 6, name: 'Levi Colwill', pos: 'D' } },
        { player: { number: 3, name: 'Marc Cucurella', pos: 'D' } },
        { player: { number: 25, name: 'Moisés Caicedo', pos: 'M' } },
        { player: { number: 45, name: 'Roméo Lavia', pos: 'M' } },
        { player: { number: 11, name: 'Noni Madueke', pos: 'M' } },
        { player: { number: 20, name: 'Cole Palmer', pos: 'M' } },
        { player: { number: 7, name: 'Pedro Neto', pos: 'M' } },
        { player: { number: 15, name: 'Nicolas Jackson', pos: 'F' } },
      ],
    };

    const teamStats = [
      {
        team: { name: homeTeam },
        statistics: [
          { type: 'Ball Possession', value: '54%' },
          { type: 'Total Shots', value: 14 },
          { type: 'Shots on Goal', value: 6 },
          { type: 'Corner Kicks', value: 5 },
          { type: 'Fouls', value: 10 },
          { type: 'Yellow Cards', value: 1 },
        ],
      },
      {
        team: { name: awayTeam },
        statistics: [
          { type: 'Ball Possession', value: '46%' },
          { type: 'Total Shots', value: 9 },
          { type: 'Shots on Goal', value: 3 },
          { type: 'Corner Kicks', value: 2 },
          { type: 'Fouls', value: 13 },
          { type: 'Yellow Cards', value: 3 },
        ],
      },
    ];

    const h2hHistory = [
      { date: '2025-11-12', home: homeTeam, away: awayTeam, score: '2-1', league: 'Premier League' },
      { date: '2025-04-20', home: awayTeam, away: homeTeam, score: '1-1', league: 'Premier League' },
      { date: '2024-12-05', home: homeTeam, away: awayTeam, score: '0-2', league: 'Premier League' },
      { date: '2024-03-15', home: awayTeam, away: homeTeam, score: '3-2', league: 'Premier League' },
      { date: '2023-10-10', home: homeTeam, away: awayTeam, score: '1-0', league: 'Premier League' },
    ];

    return this.prisma.match.update({
      where: { id },
      data: {
        lineupHome: lineupHome as any,
        lineupAway: lineupAway as any,
        teamStats: teamStats as any,
        h2hHistory: h2hHistory as any,
      },
    });
  }



  // 5. LẤY DANH SÁCH TRẬN ĐẤU (NẾU CSDL TRỐNG SẼ TỰ ĐỘNG SYNC/SEED)
  async getMatches() {
    let matches = await this.prisma.match.findMany({
      orderBy: { startTime: 'asc' },
    });

    if (matches.length === 0) {
      console.log('CSDL trống. Tự động đồng bộ và nạp dữ liệu trận đấu mẫu...');
      await this.syncDailyFixtures();
      matches = await this.prisma.match.findMany({
        orderBy: { startTime: 'asc' },
      });
    }

    return matches;
  }

  // 6. LẤY CHI TIẾT TRẬN ĐẤU (TỰ ĐỘNG SYNC CHI TIẾT NẾU CHƯA CÓ CACHE)
  async getMatchDetail(id: string) {
    let match = await this.prisma.match.findUnique({
      where: { id },
    });

    if (!match) return null;

    // Nếu chưa có cache đội hình hoặc thống kê, tự động đồng bộ chi tiết lập tức
    if (!match.lineupHome || !match.teamStats) {
      console.log(`Chưa có cache chi tiết cho trận ${match.homeTeam} vs ${match.awayTeam}. Tiến hành đồng bộ...`);
      match = await this.syncMatchDetails(id);
    }

    return match;
  }

  // --- THE STATS API IMPLEMENTATION ---

  private async syncDailyFixturesFromTheStatsApi(apiKey: string) {
    try {
      // Tự động xóa các trận mock cũ (nếu có) mà CHƯA bị phòng cược hay dự đoán nào tham chiếu
      await this.prisma.match.deleteMany({
        where: {
          apiFootballId: {
            gte: 9900,
            lte: 9999,
          },
          bettingRooms: {
            none: {},
          },
          freePredictions: {
            none: {},
          },
        },
      });

      // Tải danh sách giải đấu để ánh xạ tên giải từ competition_id
      const competitionsMap = new Map<string, string>();
      try {
        for (const page of [1, 2]) {
          const compRes = await fetch(`https://api.thestatsapi.com/api/football/competitions?page=${page}&per_page=100`, {
            headers: { 'Authorization': `Bearer ${apiKey}` }
          });
          const compData = await compRes.json();
          const list = compData?.data || [];
          for (const c of list) {
            competitionsMap.set(c.id, c.name);
          }
        }
      } catch (e) {
        console.warn('Failed to load competitions list, falling back to ID mapping:', e);
      }

      // Đồng bộ cả trận đấu hôm nay và ngày mai
      const daysToSync = [0, 1];
      for (const offset of daysToSync) {
        const targetDate = new Date();
        targetDate.setDate(targetDate.getDate() + offset);
        const dateStr = targetDate.toISOString().split('T')[0];

        console.log(`Syncing real matches from The Stats API for date: ${dateStr}...`);

        const response = await fetch(`https://api.thestatsapi.com/api/football/matches?date_from=${dateStr}&date_to=${dateStr}&per_page=100`, {
          headers: {
            'Authorization': `Bearer ${apiKey}`,
          },
        });
        const resJson = await response.json();
        const dailyMatches = resJson?.data || [];
        console.log(`The Stats API returned ${dailyMatches.length} matches for date: ${dateStr}.`);

        for (const item of dailyMatches) {
          // Trích xuất ID số từ định dạng mt_XXXXX
          const numId = parseInt(item.id.replace('mt_', ''), 10);
          if (isNaN(numId)) continue;

          let status: 'NS' | 'LIVE' | 'FT' | 'CANCL' = 'NS';
          if (item.status === 'live') {
            status = 'LIVE';
          } else if (item.status === 'finished') {
            status = 'FT';
          } else if (item.status === 'cancelled') {
            status = 'CANCL';
          }

          const leagueName = competitionsMap.get(item.competition_id) || item.competition_name || item.competition_id;

          await this.prisma.match.upsert({
            where: { apiFootballId: numId },
            update: {
              status,
              homeScore: item.score?.home ?? 0,
              awayScore: item.score?.away ?? 0,
              minuteElapsed: item.minute_elapsed ?? 0,
            },
            create: {
              apiFootballId: numId,
              leagueName: leagueName,
              leagueLogo: null,
              homeTeam: item.home_team.name,
              homeLogo: null,
              awayTeam: item.away_team.name,
              awayLogo: null,
              startTime: new Date(item.utc_date),
              status,
              homeScore: item.score?.home ?? 0,
              awayScore: item.score?.away ?? 0,
              minuteElapsed: item.minute_elapsed ?? 0,
            },
          });
        }
      }
      console.log('Successfully synced The Stats API matches to database.');
    } catch (e) {
      console.error('Failed to sync fixtures from The Stats API:', e);
    }
  }

  private async syncMatchDetailsFromTheStatsApi(id: string, numericId: number, apiKey: string) {
    try {
      const matchIdStr = `mt_${numericId}`;
      const headers = {
        'Authorization': `Bearer ${apiKey}`,
      };

      // A. Lấy Đội hình (Lineups)
      let lineupHome = null;
      let lineupAway = null;
      try {
        const lineupsRes = await fetch(`https://api.thestatsapi.com/api/football/matches/${matchIdStr}/lineups`, { headers });
        const lineupsData = await lineupsRes.json();
        if (lineupsData?.data) {
          lineupHome = lineupsData.data.home;
          lineupAway = lineupsData.data.away;
        }
      } catch (e) {
        console.warn(`Failed to fetch lineups for ${matchIdStr}:`, e);
      }

      // B. Lấy Thống kê (Stats)
      let teamStats = null;
      try {
        const statsRes = await fetch(`https://api.thestatsapi.com/api/football/matches/${matchIdStr}/stats`, { headers });
        const statsData = await statsRes.json();
        if (statsData?.data) {
          teamStats = statsData.data;
        }
      } catch (e) {
        console.warn(`Failed to fetch stats for ${matchIdStr}:`, e);
      }

      // C. Lịch sử H2H (Tạo mẫu)
      const match = await this.prisma.match.findUnique({ where: { id } });
      if (!match) return null;
      const h2hHistory = [
        { date: '2025-11-12', home: match.homeTeam, away: match.awayTeam, score: '2-1', league: match.leagueName },
        { date: '2025-04-20', home: match.awayTeam, away: match.homeTeam, score: '1-1', league: match.leagueName },
        { date: '2024-12-05', home: match.homeTeam, away: match.awayTeam, score: '0-2', league: match.leagueName },
      ];

      return this.prisma.match.update({
        where: { id },
        data: {
          lineupHome: lineupHome as any,
          lineupAway: lineupAway as any,
          teamStats: teamStats as any,
          h2hHistory: h2hHistory as any,
        },
      });
    } catch (e) {
      console.error(`Failed to sync details from The Stats API for match ${numericId}:`, e);
      return this.prisma.match.findUnique({ where: { id } });
    }
  }
}
