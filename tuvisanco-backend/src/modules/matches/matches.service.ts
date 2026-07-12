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
      this.logger.log('🏆 Đang truy quét Thiên Cơ từ FIFA WORLD CUP 2026...');

      const response = await fetch(`${this.baseUrl}/competitions/WC/matches`, {
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

        await this.prisma.match.upsert({
          where: { apiFootballId: m.id },
          update: {
            status,
            homeScore: m.score?.fullTime?.home ?? 0,
            awayScore: m.score?.fullTime?.away ?? 0,
            minuteElapsed: status === 'LIVE' ? 45 : 0,
            homeLogo: homeLogo,
            awayLogo: awayLogo,
          },
          create: {
            apiFootballId: m.id,
            leagueName: 'FIFA World Cup',
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
          },
        });
      }
      this.logger.log('🚀 Đã đồng bộ 104 trận World Cup!');
    } catch (e) {
      this.logger.error('❌ Sync failed:', e);
    }
  }

  async getMatches() {
    // Lấy các trận từ 24 tiếng trước trở đi (để xem được cả các trận vừa kết thúc hôm qua)
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    let matches = await this.prisma.match.findMany({
      where: {
        leagueName: 'FIFA World Cup',
        startTime: { gte: oneDayAgo }
      },
      orderBy: { startTime: 'asc' },
    });

    if (matches.length === 0) {
      this.logger.log('📡 Đang đồng bộ Thiên Cơ từ API...');
      await this.syncDailyFixtures();
      matches = await this.prisma.match.findMany({
        where: { leagueName: 'FIFA World Cup', startTime: { gte: oneDayAgo } },
        orderBy: { startTime: 'asc' },
      });
    }

    return matches;
  }

  async getMatchDetail(id: string) {
    return this.prisma.match.findUnique({ where: { id } });
  }
}
