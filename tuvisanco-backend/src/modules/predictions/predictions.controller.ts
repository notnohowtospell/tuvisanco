import { Controller, Post, Body } from '@nestjs/common';
import { PredictionsService } from './predictions.service';

@Controller('predictions')
export class PredictionsController {
  constructor(private readonly predictionsService: PredictionsService) {}

  @Post()
  async submitPrediction(
    @Body() body: { userId: string; matchId: string; predictedHomeScore: number; predictedAwayScore: number; isJoker?: boolean }
  ) {
    return this.predictionsService.submitPrediction(body.userId, body);
  }
}
