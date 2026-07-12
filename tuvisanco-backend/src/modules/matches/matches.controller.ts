import { Controller, Get, Param, Post, Query } from '@nestjs/common';
import { MatchesService } from './matches.service';

@Controller('matches')
export class MatchesController {
  constructor(private readonly matchesService: MatchesService) {}

  // NÂNG CẤP: Cho phép Flutter truyền query ?date=2026-07-11 để lọc trận theo ngày
  @Get()
  async getMatches(@Query('date') date?: string) {
    // Nếu bạn muốn giữ nguyên logic cũ, cứ để nguyên return this.matchesService.getMatches();
    // Còn nếu muốn lọc theo ngày, bạn có thể xử lý thêm ở Service sau này nhé.
    return this.matchesService.getMatches();
  }

  // Giữ nguyên - Quá chuẩn để xem chi tiết trận đấu
  @Get(':id')
  async getMatchDetail(@Param('id') id: string) {
    return this.matchesService.getMatchDetail(id);
  }

  // Giữ nguyên - Để các bạn dùng Postman hoặc công cụ bấm phát là tự đồng bộ dữ liệu mới từ Sofascore về DB
  @Post('sync')
  async triggerSync() {
    await this.matchesService.syncDailyFixtures();
    return { success: true, message: 'Đồng bộ dữ liệu từ Sofascore thành công!' };
  }
}