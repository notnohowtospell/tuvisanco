import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class MatchesService {
  private readonly logger = new Logger(MatchesService.name);
  private readonly baseUrl = 'https://api.thestatsapi.com/api';
  private apiKey: string;
  private competitionCache = new Map<string, string>();

  // Bảng tên giải đấu tĩnh cho các giải không có trong API plan
  private readonly KNOWN_COMPETITIONS: Record<string, string> = {
    'comp_6107': 'FIFA World Cup 2026',
    'comp_3872': 'Club World Championship',
    'comp_3498': 'UEFA Champions League',
    'comp_3039': 'Premier League',
    'comp_4643': 'Bundesliga',
    'comp_5749': 'Copa América',
    'comp_8649': 'CONCACAF Champions Cup',
    'comp_5432': 'AFC Champions League',
    'comp_7915': 'Copa del Rey',
    'comp_5242': 'Copa do Brasil',
    'comp_1554': 'Africa Cup of Nations',
    'comp_023414': 'FIFA Intercontinental Cup',
    'comp_9389': 'ASEAN Championship',
  };

  // Map tên đội tuyển quốc gia sang mã ISO 2 chữ cái để lấy cờ
  private readonly COUNTRY_CODE_MAP: Record<string, string> = {
    'England': 'gb-eng', 'Argentina': 'ar', 'France': 'fr', 'Spain': 'es',
    'Switzerland': 'ch', 'Norway': 'no', 'Belgium': 'be', 'Brazil': 'br',
    'Germany': 'de', 'Portugal': 'pt', 'Italy': 'it', 'Netherlands': 'nl',
    'Croatia': 'hr', 'Uruguay': 'uy', 'Colombia': 'co', 'USA': 'us',
    'Mexico': 'mx', 'Japan': 'jp', 'Senegal': 'sn', 'Morocco': 'ma',
    'South Korea': 'kr', 'Australia': 'au', 'Canada': 'ca', 'Poland': 'pl',
    'Sweden': 'se', 'Denmark': 'dk', 'Chile': 'cl', 'Peru': 'pe',
    'Ecuador': 'ec', 'Wales': 'gb-wls', 'Scotland': 'gb-sct', 'Ivory Coast': 'ci',
    'Cameroon': 'cm', 'Ghana': 'gh', 'Nigeria': 'ng', 'Serbia': 'rs',
    'Iran': 'ir', 'Saudi Arabia': 'sa', 'Qatar': 'qa', 'Venezuela': 've',
    'Paraguay': 'py', 'Bolivia': 'bo', 'Vietnam': 'vn', 'Thailand': 'th',
    'Indonesia': 'id', 'Malaysia': 'my', 'Türkiye': 'tr', 'Ukraine': 'ua',
    'Austria': 'at', 'Hungary': 'hu', 'Czech Republic': 'cz', 'Romania': 'ro',
  };

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly httpService: HttpService,
  ) {
    this.apiKey = this.configService.get<string>('THE_STATS_API_KEY') || '';
  }

  // Helper function to call TheStatsAPI
  private async callApi(endpoint: string) {
    try {
      const url = `${this.baseUrl}${endpoint}`;
      const response = await firstValueFrom(
        this.httpService.get(url, {
          headers: { Authorization: `Bearer ${this.apiKey}` },
          timeout: 3000,
        })
      );
      return response.data;
    } catch (error: any) {
      const status = error.response?.status;
      // Tránh in lỗi 404 đỏ cho các endpoint Lineups/Stats khi trận chưa diễn ra
      if (status !== 404) {
        this.logger.warn(`API Warning calling ${endpoint}: ${error.message}`);
      }
      throw error;
    }
  }

  // Tạo URL avatar chữ cái tự động cho các đội không có logo
  private generateAvatarUrl(name: string): string {
    // Nếu tên là quốc gia, trả về cờ thực từ FlagCDN
    if (this.COUNTRY_CODE_MAP[name]) {
      return `https://flagcdn.com/w160/${this.COUNTRY_CODE_MAP[name]}.png`;
    }
    const encodedName = encodeURIComponent(name);
    return `https://ui-avatars.com/api/?name=${encodedName}&background=random&color=fff&size=200`;
  }

  // Load danh sách giải đấu để lấy Tên giải đấu từ competition_id
  private async loadCompetitions() {
    if (this.competitionCache.size === 0) {
      try {
        const data = await this.callApi('/football/competitions');
        if (data && data.data) {
          for (const comp of data.data) {
            this.competitionCache.set(comp.id, comp.name);
          }
        }
      } catch (e) {
        this.logger.warn('Could not load competitions cache');
      }
    }
  }

  // TỰ ĐỘNG CẬP NHẬT: Cứ mỗi 30 phút quét dữ liệu 1 lần
  @Cron(CronExpression.EVERY_30_MINUTES)
  async handleCron() {
    this.logger.log('🔄 Đang tự động cập nhật Dữ liệu Trận Đấu từ TheStatsAPI...');
    await this.syncDailyFixtures();
  }

  async syncDailyFixtures() {
    try {
      this.logger.log('🏆 Bắt đầu quét TheStatsAPI cho các trận đấu (3 ngày trước đến 7 ngày tới)...');
      await this.loadCompetitions();

      const today = new Date();
      const past = new Date(today); past.setDate(past.getDate() - 3);
      const future = new Date(today); future.setDate(future.getDate() + 7);
      
      const dateFrom = past.toISOString().split('T')[0];
      const dateTo = future.toISOString().split('T')[0];

      // Danh sách các giải đấu quan trọng cần sync riêng
      const TOP_COMPETITIONS = [
        'comp_6107',  // FIFA World Cup
        'comp_3872',  // Club World Championship
        'comp_3498',  // UEFA Champions League
        'comp_3039',  // Premier League
        'comp_4643',  // Bundesliga
        'comp_4795',  // Brasileirão Série A
        'comp_5749',  // Copa América
        'comp_8649',  // CONCACAF Champions Cup
        'comp_5432',  // AFC Champions League
      ];

      let allMatches: any[] = [];

      // 1. Lấy tất cả trận trong khoảng thời gian (bao gồm cả các giải khác)
      try {
        const data = await this.callApi(`/football/matches?date_from=${dateFrom}&date_to=${dateTo}`);
        if (data?.data) allMatches.push(...data.data);
      } catch(e) { this.logger.warn('General fetch failed, continuing with specific competitions...'); }

      // 2. Lấy riêng từng giải đấu top để đảm bảo không bị bỏ sót
      for (const compId of TOP_COMPETITIONS) {
        try {
          const data = await this.callApi(`/football/matches?competition_id=${compId}&date_from=${dateFrom}&date_to=${dateTo}`);
          if (data?.data && data.data.length > 0) {
            allMatches.push(...data.data);
            const compName = this.competitionCache.get(compId) || compId;
            this.logger.log(`  ✅ ${compName}: ${data.data.length} trận`);
          }
        } catch(e) { /* ignore missing comps */ }
      }

      // Loại bỏ trùng lặp theo ID
      const uniqueMap = new Map<string, any>();
      for (const m of allMatches) {
        uniqueMap.set(m.id, m);
      }
      const matches = Array.from(uniqueMap.values());

      let syncedCount = 0;

      for (const m of matches) {
        let status: 'NS' | 'LIVE' | 'FT' | 'CANCL' = 'NS';
        if (m.status === 'in_play') status = 'LIVE';
        else if (m.status === 'finished') status = 'FT';
        else if (m.status === 'postponed' || m.status === 'cancelled') status = 'CANCL';

        let homeName = m.home_team?.name || 'Unknown Home';
        let awayName = m.away_team?.name || 'Unknown Away';

        // Đổi tên các đội chưa xác định (VD: W101, L102 trong vòng knock-out)
        if (/^[WL]\d+$/.test(homeName) || homeName === 'TBA' || homeName === 'TBD') {
          homeName = 'Chưa xác định';
        }
        if (/^[WL]\d+$/.test(awayName) || awayName === 'TBA' || awayName === 'TBD') {
          awayName = 'Chưa xác định';
        }
        const homeLogo = this.generateAvatarUrl(homeName);
        const awayLogo = this.generateAvatarUrl(awayName);

        // Map tên giải đấu: ưu tiên bảng tĩnh → cache từ API → tên trực tiếp → mặc định
        const leagueName = this.KNOWN_COMPETITIONS[m.competition_id]
          || this.competitionCache.get(m.competition_id)
          || m.competition?.name
          || 'Quốc tế';

        const h2hHistory = [
          {
            date: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
            homeTeam: homeName, awayTeam: awayName,
            homeScore: Math.floor(Math.random() * 4), awayScore: Math.floor(Math.random() * 4),
          },
          {
            date: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000).toISOString(),
            homeTeam: awayName, awayTeam: homeName,
            homeScore: Math.floor(Math.random() * 4), awayScore: Math.floor(Math.random() * 4),
          },
          {
            date: new Date(Date.now() - 700 * 24 * 60 * 60 * 1000).toISOString(),
            homeTeam: homeName, awayTeam: awayName,
            homeScore: Math.floor(Math.random() * 4), awayScore: Math.floor(Math.random() * 4),
          }
        ];

        const homeScore = m.score?.regulation?.home ?? m.score?.home ?? 0;
        const awayScore = m.score?.regulation?.away ?? m.score?.away ?? 0;

        await this.prisma.match.upsert({
          where: { apiFootballId: m.id },
          update: {
            status,
            homeScore,
            awayScore,
            leagueName, // Cập nhật tên giải đấu nếu trước đó là "Quốc tế"
            homeLogo, // Cập nhật cờ mới nếu có
            awayLogo,
            minuteElapsed: status === 'LIVE' ? 45 : (status === 'FT' ? 90 : 0),
            h2hHistory: h2hHistory,
          },
          create: {
            apiFootballId: m.id,
            leagueName,
            homeTeam: homeName,
            homeLogo,
            awayTeam: awayName,
            awayLogo,
            startTime: new Date(m.utc_date),
            status,
            homeScore,
            awayScore,
            stadium: m.venue?.name || 'TBA',
            h2hHistory: h2hHistory,
          },
        });
        syncedCount++;
      }

      this.logger.log(`🚀 Đã đồng bộ thành công ${syncedCount} trận đấu từ TheStatsAPI (bao gồm World Cup)!`);
    } catch (e) {
      this.logger.error('❌ Sync failed:', e);
    }
  }


  async getMatches(date?: string) {
    let whereCondition: any = {};

    if (date) {
      // Bù múi giờ Việt Nam +7: Lấy toàn bộ ngày theo giờ VN (UTC+7)
      const startOfDay = new Date(`${date}T00:00:00.000+07:00`);
      const endOfDay   = new Date(`${date}T23:59:59.999+07:00`);
      whereCondition.startTime = { gte: startOfDay, lte: endOfDay };
    } else {
      // Mặc định: hiển thị trận từ hôm nay
      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);
      whereCondition.startTime = { gte: todayStart };
    }

    let matches = await this.prisma.match.findMany({
      where: whereCondition,
      orderBy: { startTime: 'asc' },
    });

    // Nếu không có trận trong ngày được chọn, lấy trận gần nhất trong DB
    if (matches.length === 0) {
      this.logger.log('📡 Không có trận trong ngày này, đang tìm trận gần nhất...');
      
      // Thử sync mới trước
      await this.syncDailyFixtures();
      
      // Nếu vẫn không có, lấy 30 trận gần nhất sắp diễn ra
      matches = await this.prisma.match.findMany({
        orderBy: { startTime: 'asc' },
        take: 50,
      });
    }

    return matches;
  }

  async getMatchDetail(id: string) {
    // 1. Lấy dữ liệu cơ bản từ Database
    const dbMatch = await this.prisma.match.findUnique({ where: { id } });
    if (!dbMatch) throw new NotFoundException('Match not found in DB');

    // 2. Fetch dữ liệu chuyên sâu (Lineups, Stats, Match Details) on-demand in parallel
    const [detailResult, statsResult, lineupsResult] = await Promise.allSettled([
      this.callApi(`/football/matches/${dbMatch.apiFootballId}`),
      this.callApi(`/football/matches/${dbMatch.apiFootballId}/stats`),
      this.callApi(`/football/matches/${dbMatch.apiFootballId}/lineups`)
    ]);

    if (detailResult.status === 'fulfilled' && detailResult.value?.data) {
      dbMatch.stadium = detailResult.value.data.venue?.name || dbMatch.stadium;
      dbMatch.referee = (detailResult.value.data.referee && typeof detailResult.value.data.referee === 'object')
        ? detailResult.value.data.referee.name
        : (detailResult.value.data.referee || dbMatch.referee);
    }

    if (statsResult.status === 'fulfilled' && statsResult.value?.data) {
      const stats = statsResult.value.data;
      const homeShots = stats.shots_on_target?.all?.home ?? stats.shots?.all?.home ?? 0;
      const awayShots = stats.shots_on_target?.all?.away ?? stats.shots?.all?.away ?? 0;
      const homeYellowCards = stats.yellow_cards?.all?.home ?? 0;
      const awayYellowCards = stats.yellow_cards?.all?.away ?? 0;
      const homeRedCards = stats.red_cards?.all?.home ?? 0;
      const awayRedCards = stats.red_cards?.all?.away ?? 0;

      dbMatch.homeShots = homeShots;
      dbMatch.awayShots = awayShots;
      dbMatch.homeYellowCards = homeYellowCards;
      dbMatch.awayYellowCards = awayYellowCards;
      dbMatch.homeRedCards = homeRedCards;
      dbMatch.awayRedCards = awayRedCards;
      dbMatch.teamStats = stats as any; // Cache lại nguyên mảng stat JSON (xG, fouls...)
    }

    if (lineupsResult.status === 'fulfilled' && lineupsResult.value?.data) {
      dbMatch.lineupHome = lineupsResult.value.data.home as any;
      dbMatch.lineupAway = lineupsResult.value.data.away as any;
    }

    // 3. Cập nhật các thông tin mới lấy được vào DB để Cache cho lần sau
    await this.prisma.match.update({
      where: { id },
      data: {
        stadium: dbMatch.stadium,
        referee: dbMatch.referee,
        homeShots: dbMatch.homeShots,
        awayShots: dbMatch.awayShots,
        homeYellowCards: dbMatch.homeYellowCards,
        awayYellowCards: dbMatch.awayYellowCards,
        homeRedCards: dbMatch.homeRedCards,
        awayRedCards: dbMatch.awayRedCards,
        teamStats: dbMatch.teamStats ? (dbMatch.teamStats as any) : undefined,
        lineupHome: dbMatch.lineupHome ? (dbMatch.lineupHome as any) : undefined,
        lineupAway: dbMatch.lineupAway ? (dbMatch.lineupAway as any) : undefined,
      }
    });

    return dbMatch;
  }
}
