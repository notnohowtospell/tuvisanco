import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class MatchesService {
  constructor(private readonly prisma: PrismaService) {}

  async syncDailyFixtures() {
    const apiKey = process.env.RAPIDAPI_FOOTBALL_KEY;
    if (!apiKey || apiKey === 'your_api_football_rapidapi_key') {
      console.warn('API-Football Key is not configured. Skipping sync.');
      return;
    }

    try {
      // Example call to API-Football via native node fetch
      const response = await fetch('https://api-football-v1.p.rapidapi.com/v3/fixtures?date=2026-07-08', {
        headers: {
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': 'api-football-v1.p.rapidapi.com',
        },
      });
      const data = await response.json();
      // TODO: Map and upsert matches to PostgreSQL via Prisma
      console.log('Seeded matches count:', data?.response?.length || 0);
    } catch (e) {
      console.error('Failed to sync fixtures from API-Football:', e);
    }
  }

  async getMatches() {
    return this.prisma.match.findMany({
      orderBy: { startTime: 'asc' },
    });
  }

  async getMatchDetail(id: string) {
    return this.prisma.match.findUnique({
      where: { id },
    });
  }
}
