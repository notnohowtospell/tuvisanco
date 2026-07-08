import { Controller, Get, Post, Body } from '@nestjs/common';
import { NewsService } from './news.service';

@Controller('news')
export class NewsController {
  constructor(private readonly newsService: NewsService) {}

  @Get()
  async getNews() {
    return this.newsService.getNews();
  }

  @Post()
  async createNews(
    @Body() body: { title: string; summary: string; content: string; imageUrl?: string; sourceUrl?: string }
  ) {
    return this.newsService.createNews(body);
  }
}
