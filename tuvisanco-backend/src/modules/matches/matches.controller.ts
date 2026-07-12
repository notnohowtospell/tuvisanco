import { Controller, Get, Param, Post, Query, Res } from '@nestjs/common';
import { MatchesService } from './matches.service';
import type { Response } from 'express';

@Controller('matches')
export class MatchesController {
  constructor(private readonly matchesService: MatchesService) {}

  // NÂNG CẤP: Cho phép Flutter truyền query ?date=2026-07-11 để lọc trận theo ngày
  @Get()
  async getMatches(@Query('date') date?: string) {
    return this.matchesService.getMatches(date);
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

  // Proxy nội bộ để khắc phục lỗi CORS của flutter_svg trên Web
  @Get('proxy/image')
  async proxyImage(@Query('url') url: string, @Res() res: Response) {
    if (!url) return res.status(400).send('No URL provided');
    try {
      const response = await fetch(url);
      const buffer = await response.arrayBuffer();
      const contentType = response.headers.get('content-type') || 'image/svg+xml';
      res.setHeader('Content-Type', contentType);
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.send(Buffer.from(buffer));
    } catch (e) {
      res.status(500).send('Error proxying image');
    }
  }
}