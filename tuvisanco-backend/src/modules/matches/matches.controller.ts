import { Controller, Get, Param, Post } from '@nestjs/common';
import { MatchesService } from './matches.service';

@Controller('matches')
export class MatchesController {
  constructor(private readonly matchesService: MatchesService) {}

  @Get()
  async getMatches() {
    return this.matchesService.getMatches();
  }

  @Get(':id')
  async getMatchDetail(@Param('id') id: string) {
    return this.matchesService.getMatchDetail(id);
  }

  @Post('sync')
  async triggerSync() {
    await this.matchesService.syncDailyFixtures();
    return { success: true, message: 'Sync triggered successfully' };
  }
}
