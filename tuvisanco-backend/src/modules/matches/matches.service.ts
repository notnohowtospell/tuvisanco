import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class MatchesService {
  private readonly logger = new Logger(MatchesService.name);
  private readonly baseUrl = 'https://api.football-data.org/v4';
  private readonly WC_TOKEN = '41d468be7af24f7d8c94b86cb73d30a6';

  constructor(private readonly prisma: PrismaService) {}

  // TỰ ĐỘNG CẬP NHẬT: Cứ mỗi 1 phút sẽ tự động quét API để cập nhật tỉ số mới nhất
  @Cron(CronExpression.EVERY_MINUTE)
  async handleCron() {
    this.logger.log('🔄 Đang tự động cập nhật Thiên Cơ (Tỉ số World Cup)...');
    await this.syncDailyFixtures();
  }

  async syncDailyFixtures() {
    try {
      this.logger.log('🏆 Đang truy quét Thiên Cơ từ toàn bộ các giải đấu trong 10 ngày...');

      const today = new Date();
      const past = new Date(today); past.setDate(past.getDate() - 5);
      const future = new Date(today); future.setDate(future.getDate() + 5);
      
      const dateFrom = past.toISOString().split('T')[0];
      const dateTo = future.toISOString().split('T')[0];

      const response = await fetch(`${this.baseUrl}/matches?dateFrom=${dateFrom}&dateTo=${dateTo}`, {
        headers: { 'X-Auth-Token': this.WC_TOKEN },
      });

      if (!response.ok) throw new Error('API Error');

      const data = await response.json();
      const wcMatches = data.matches || [];

      for (const m of wcMatches) {
        // 1. Xử lý trạng thái
        let status: 'NS' | 'LIVE' | 'FT' | 'CANCL' = 'NS';
        if (['IN_PLAY', 'PAUSED'].includes(m.status)) status = 'LIVE';
        else if (['FINISHED'].includes(m.status)) status = 'FT';

        // 2. Xử lý tên đội và Ảnh (Crest)
        const homeName = m.homeTeam?.shortName || m.homeTeam?.name || 'Chờ xác định';
        const awayName = m.awayTeam?.shortName || m.awayTeam?.name || 'Chờ xác định';
        const homeLogo = m.homeTeam?.crest || null;
        const awayLogo = m.awayTeam?.crest || null;

        // 3. Xử lý sân vận động và trọng tài
        const stadiums = ['MetLife Stadium', 'AT&T Stadium', 'SoFi Stadium', 'Levi\'s Stadium', 'Hard Rock Stadium'];
        const referees = ['Daniele Orsato', 'Szymon Marciniak', 'Anthony Taylor', 'Wilton Sampaio', 'Michael Oliver'];
        const stadium = m.venue?.name || stadiums[Math.floor(Math.random() * stadiums.length)];
        const referee = m.referees && m.referees.length > 0 ? m.referees[0].name : referees[Math.floor(Math.random() * referees.length)];

        // 4. Mock lịch sử đối đầu (H2H)
        const h2hHistory = [
          {
            date: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
            homeTeam: homeName,
            awayTeam: awayName,
            homeScore: Math.floor(Math.random() * 4),
            awayScore: Math.floor(Math.random() * 4),
          },
          {
            date: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000).toISOString(),
            homeTeam: awayName,
            awayTeam: homeName,
            homeScore: Math.floor(Math.random() * 4),
            awayScore: Math.floor(Math.random() * 4),
          },
          {
            date: new Date(Date.now() - 700 * 24 * 60 * 60 * 1000).toISOString(),
            homeTeam: homeName,
            awayTeam: awayName,
            homeScore: Math.floor(Math.random() * 4),
            awayScore: Math.floor(Math.random() * 4),
          }
        ];

        const leagueName = m.competition?.name || 'Quốc tế';

        await this.prisma.match.upsert({
          where: { apiFootballId: m.id },
          update: {
            status,
            homeScore: m.score?.fullTime?.home ?? 0,
            awayScore: m.score?.fullTime?.away ?? 0,
            minuteElapsed: status === 'LIVE' ? 45 : 0,
            homeLogo: homeLogo,
            awayLogo: awayLogo,
            stadium,
            referee,
            h2hHistory,
          },
          create: {
            apiFootballId: m.id,
            leagueName: leagueName,
            homeTeam: homeName,
            homeLogo: homeLogo,
            awayTeam: awayName,
            awayLogo: awayLogo,
            startTime: new Date(m.utcDate),
            status,
            homeScore: m.score?.fullTime?.home ?? 0,
            awayScore: m.score?.fullTime?.away ?? 0,
            // Mock stats cho đẹp UI như ảnh
            homeShots: Math.floor(Math.random() * 10) + 5,
            awayShots: Math.floor(Math.random() * 10) + 5,
            homeYellowCards: Math.floor(Math.random() * 3),
            awayYellowCards: Math.floor(Math.random() * 3),
            stadium,
            referee,
            h2hHistory,
          },
        });
      }
      // --- BẮT ĐẦU MOCK DỮ LIỆU ---
      const TOP_13_LEAGUES = [
        "FIFA World Cup", "UEFA Champions League", "Premier League", "Primera Division",
        "Serie A", "Bundesliga", "Ligue 1", "Championship", "Eredivisie",
        "Primeira Liga", "Campeonato Brasileiro Série A", "Copa Libertadores", "DFB Pokal"
      ];

      const existingLeagues = new Set(wcMatches.map((m: any) => m.competition?.name));
      const missingLeagues = TOP_13_LEAGUES.filter(l => !existingLeagues.has(l));

      for (const league of missingLeagues) {
        const mockCount = Math.floor(Math.random() * 3) + 2; // 2 to 4 matches
        for (let i = 0; i < mockCount; i++) {
          const mockId = 9000000 + TOP_13_LEAGUES.indexOf(league) * 10 + i;
          const statusOptions: ('NS' | 'LIVE' | 'FT')[] = ['NS', 'LIVE', 'FT'];
          const status = statusOptions[Math.floor(Math.random() * statusOptions.length)];
          const homeScore = Math.floor(Math.random() * 4);
          const awayScore = Math.floor(Math.random() * 4);

          await this.prisma.match.upsert({
            where: { apiFootballId: mockId },
            update: {
              status,
              homeScore,
              awayScore,
              minuteElapsed: status === 'LIVE' ? 45 : 0,
            },
            create: {
              apiFootballId: mockId,
              leagueName: league,
              homeTeam: `Đội nhà ${league} ${i+1}`,
              homeLogo: 'https://crests.football-data.org/769.svg',
              awayTeam: `Đội khách ${league} ${i+1}`,
              awayLogo: 'https://crests.football-data.org/774.svg',
              startTime: new Date(Date.now() + (Math.random() - 0.5) * 24 * 60 * 60 * 1000),
              status,
              homeScore,
              awayScore,
              homeShots: Math.floor(Math.random() * 10) + 5,
              awayShots: Math.floor(Math.random() * 10) + 5,
              homeYellowCards: Math.floor(Math.random() * 3),
              awayYellowCards: Math.floor(Math.random() * 3),
              stadium: "Sân vận động Mock",
              referee: "Trọng tài Mock",
              h2hHistory: []
            }
          });
        }
      }
      // --- KẾT THÚC MOCK DỮ LIỆU ---

      this.logger.log('🚀 Đã đồng bộ thành công dữ liệu thật và giả lập 13 giải!');
    } catch (e) {
      this.logger.error('❌ Sync failed:', e);
    }
  }

  async getMatches(date?: string) {
    let whereCondition: any = {};

    if (date) {
      // Lọc từ 00:00:00 đến 23:59:59 của ngày được chọn
      const startOfDay = new Date(`${date}T00:00:00.000Z`);
      const endOfDay = new Date(`${date}T23:59:59.999Z`);
      whereCondition.startTime = { gte: startOfDay, lte: endOfDay };
    } else {
      // Mặc định: Lấy các trận từ 24 tiếng trước trở đi
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      whereCondition.startTime = { gte: oneDayAgo };
    }

    let matches = await this.prisma.match.findMany({
      where: whereCondition,
      orderBy: { startTime: 'asc' },
    });

    // Chỉ tự động sync nếu không truyền date (hoặc date là hôm nay), để tránh spam sync khi xem các ngày không có trận
    if (matches.length === 0 && !date) {
      this.logger.log('📡 Đang đồng bộ Thiên Cơ từ API...');
      await this.syncDailyFixtures();
      matches = await this.prisma.match.findMany({
        where: whereCondition,
        orderBy: { startTime: 'asc' },
      });
    }

    return matches;
  }

  async getMatchDetail(id: string) {
    return this.prisma.match.findUnique({ where: { id } });
  }
}
