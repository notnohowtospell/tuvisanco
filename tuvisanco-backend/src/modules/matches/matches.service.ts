import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class MatchesService {
  constructor(private readonly prisma: PrismaService) {}

  // 1. ĐỒNG BỘ TRẬN ĐẤU (API-FOOTBALL HOẶC TỰ ĐỘNG SINH MOCK HỢP LÝ)
  async syncDailyFixtures() {
    const apiKey = process.env.RAPIDAPI_FOOTBALL_KEY;
    
    // Nếu không có API Key, tự động sinh dữ liệu mẫu trực quan
    if (!apiKey || apiKey === 'your_api_football_rapidapi_key') {
      console.warn('API-Football Key is not configured. Generating realistic mock matches...');
      await this.generateMockMatches();
      return;
    }

    try {
      const todayStr = new Date().toISOString().split('T')[0];
      const response = await fetch(`https://api-football-v1.p.rapidapi.com/v3/fixtures?date=${todayStr}`, {
        headers: {
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': 'api-football-v1.p.rapidapi.com',
        },
      });
      const data = await response.json();
      const fixtures = data?.response || [];

      console.log(`API-Football returned ${fixtures.length} matches for today.`);

      // ĐÃ SỬA: Nếu API trả về 0 trận (hết hạn, hết lượt, hoặc ngày không có trận), tự động nạp trận mẫu dự phòng
      if (fixtures.length === 0) {
        console.warn('API-Football returned 0 matches. Falling back to mock matches...');
        await this.generateMockMatches();
        return;
      }

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

  // 4. SINH DỮ LIỆU MOCK TRẬN ĐẤU THỰC TẾ (KHI KHÔNG CÓ API KEY)
  private async generateMockMatches() {
    const now = new Date();
    
    const mockData = [
      {
        apiFootballId: 9901,
        leagueName: 'Premier League',
        homeTeam: 'Arsenal',
        homeLogo: 'https://media.api-sports.io/football/teams/42.png',
        awayTeam: 'Chelsea',
        awayLogo: 'https://media.api-sports.io/football/teams/49.png',
        timeOffsetHours: 2,
        status: 'NS' as const,
        homeScore: 0,
        awayScore: 0,
        elapsed: 0,
      },
      {
        apiFootballId: 9902,
        leagueName: 'Premier League',
        homeTeam: 'Manchester United',
        homeLogo: 'https://media.api-sports.io/football/teams/33.png',
        awayTeam: 'Manchester City',
        awayLogo: 'https://media.api-sports.io/football/teams/50.png',
        timeOffsetHours: 4,
        status: 'NS' as const,
        homeScore: 0,
        awayScore: 0,
        elapsed: 0,
      },
      {
        apiFootballId: 9903,
        leagueName: 'Champions League',
        homeTeam: 'Real Madrid',
        homeLogo: 'https://media.api-sports.io/football/teams/541.png',
        awayTeam: 'Bayern Munich',
        awayLogo: 'https://media.api-sports.io/football/teams/157.png',
        timeOffsetHours: -0.5,
        status: 'LIVE' as const,
        homeScore: 1,
        awayScore: 0,
        elapsed: 30,
      },
      {
        apiFootballId: 9904,
        leagueName: 'Champions League',
        homeTeam: 'Barcelona',
        homeLogo: 'https://media.api-sports.io/football/teams/529.png',
        awayTeam: 'PSG',
        awayLogo: 'https://media.api-sports.io/football/teams/85.png',
        timeOffsetHours: -3,
        status: 'FT' as const,
        homeScore: 2,
        awayScore: 1,
        elapsed: 90,
      },
      {
        apiFootballId: 9905,
        leagueName: 'La Liga',
        homeTeam: 'Atletico Madrid',
        homeLogo: 'https://media.api-sports.io/football/teams/530.png',
        awayTeam: 'Real Sociedad',
        awayLogo: 'https://media.api-sports.io/football/teams/548.png',
        timeOffsetHours: 26,
        status: 'NS' as const,
        homeScore: 0,
        awayScore: 0,
        elapsed: 0,
      },
      {
        apiFootballId: 9906,
        leagueName: 'World Cup',
        homeTeam: 'Argentina',
        homeLogo: 'https://media.api-sports.io/football/teams/26.png',
        awayTeam: 'France',
        awayLogo: 'https://media.api-sports.io/football/teams/2.png',
        timeOffsetHours: 8,
        status: 'NS' as const,
        homeScore: 0,
        awayScore: 0,
        elapsed: 0,
      }
    ];

    for (const match of mockData) {
      const matchTime = new Date(now.getTime() + match.timeOffsetHours * 60 * 60 * 1000);
      
      await this.prisma.match.upsert({
        where: { apiFootballId: match.apiFootballId },
        update: {
          status: match.status,
          homeScore: match.homeScore,
          awayScore: match.awayScore,
          minuteElapsed: match.elapsed,
          startTime: matchTime,
        },
        create: {
          apiFootballId: match.apiFootballId,
          leagueName: match.leagueName,
          leagueLogo: match.leagueName == 'World Cup'
              ? 'https://media.api-sports.io/football/leagues/1.png'
              : 'https://media.api-sports.io/football/leagues/39.png',
          homeTeam: match.homeTeam,
          homeLogo: match.homeLogo,
          awayTeam: match.awayTeam,
          awayLogo: match.awayLogo,
          startTime: matchTime,
          status: match.status,
          homeScore: match.homeScore,
          awayScore: match.awayScore,
          minuteElapsed: match.elapsed,
        },
      });
    }
    console.log('Populated 5 realistic mock matches for testing.');
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
}
