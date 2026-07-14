import { Controller, Post, Param, Body } from '@nestjs/common';
import { AiService } from './ai.service';

@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('predict/:matchId')
  async predict(@Param('matchId') matchId: string) {
    return this.aiService.predictMatchProbability(matchId);
  }

  @Post('chat')
  async chat(@Body('message') message: string) {
    return this.aiService.chat(message);
  }
}
