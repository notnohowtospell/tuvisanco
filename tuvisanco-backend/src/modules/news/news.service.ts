import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class NewsService {
  constructor(private readonly prisma: PrismaService) {}

  async getNews() {
    return this.prisma.news.findMany({
      orderBy: { publishedAt: 'desc' },
      take: 20,
    });
  }

  async createNews(data: { title: string; summary: string; content: string; imageUrl?: string; sourceUrl?: string }) {
    return this.prisma.news.create({
      data,
    });
  }
}
