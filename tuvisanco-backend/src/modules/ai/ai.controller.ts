import { Controller, Post, Param } from '@nestjs/common';
import { AiService } from './ai.service';

@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('predict/:matchId')
  async predict(@Param('matchId') matchId: string) {
    return this.aiService.predictMatchProbability(matchId);
  }
}
