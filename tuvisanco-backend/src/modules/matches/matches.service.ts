import { Injectable } from '@nestjs/common';
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

      for (const item of fixtures) {
        // Map trạng thái trận đấu
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

  // 2. SINH DỮ LIỆU MOCK TRẬN ĐẤU THỰC TẾ (KHI KHÔNG CÓ API KEY)
  private async generateMockMatches() {
    const now = new Date();
    
    // Mảng dữ liệu trận đấu Ngoại Hạng Anh & UCL mẫu cực đẹp
    const mockData = [
      {
        apiFootballId: 9901,
        leagueName: 'Premier League',
        homeTeam: 'Arsenal',
        homeLogo: 'https://media.api-sports.io/football/teams/42.png',
        awayTeam: 'Chelsea',
        awayLogo: 'https://media.api-sports.io/football/teams/49.png',
        timeOffsetHours: 2, // 2 tiếng nữa đá (NS)
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
        timeOffsetHours: 4, // 4 tiếng nữa đá (NS)
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
        timeOffsetHours: -0.5, // Đang đá hiệp 1 (LIVE)
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
        timeOffsetHours: -3, // Đã kết thúc (FT)
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
        timeOffsetHours: 26, // Ngày mai đá (NS)
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
          leagueLogo: 'https://media.api-sports.io/football/leagues/39.png',
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

  // 3. LẤY DANH SÁCH TRẬN ĐẤU (NẾU CSDL TRỐNG SẼ TỰ ĐỘNG SYNC/SEED)
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

  // 4. LẤY CHI TIẾT TRẬN ĐẤU
  async getMatchDetail(id: string) {
    return this.prisma.match.findUnique({
      where: { id },
    });
  }
}
