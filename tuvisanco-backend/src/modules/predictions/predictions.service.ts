import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class PredictionsService {
  constructor(private readonly prisma: PrismaService) {}

  async submitPrediction(userId: string, data: { matchId: string; predictedHomeScore: number; predictedAwayScore: number; isJoker?: boolean }) {
    return this.prisma.prediction.create({
      data: {
        userId,
        matchId: data.matchId,
        predictedHomeScore: data.predictedHomeScore,
        predictedAwayScore: data.predictedAwayScore,
        isJoker: data.isJoker || false,
      },
    });
  }

  // Thuật toán tính điểm dự đoán Bundesliga Tippspiel/Superbru cải tiến
  async calculatePredictionScore(predictionId: string, actualHomeScore: number, actualAwayScore: number) {
    const prediction = await this.prisma.prediction.findUnique({ where: { id: predictionId } });
    if (!prediction) return 0;

    let points = 0;
    const predHome = prediction.predictedHomeScore;
    const predAway = prediction.predictedAwayScore;

    const actualOutcome = actualHomeScore > actualAwayScore ? 1 : actualHomeScore < actualAwayScore ? -1 : 0;
    const predOutcome = predHome > predAway ? 1 : predHome < predAway ? -1 : 0;

    if (predHome === actualHomeScore && predAway === actualAwayScore) {
      // 1. Đúng tỷ số chính xác
      points = 3;
    } else if (predOutcome === actualOutcome && (predHome - predAway === actualHomeScore - actualAwayScore)) {
      // 2. Đúng đội thắng + Đúng hiệu số bàn thắng cách biệt
      points = 2;
    } else if (predOutcome === actualOutcome) {
      // 3. Chỉ đúng kết quả thắng/thua/hòa
      points = 1;
    }

    if (prediction.isJoker) {
      points *= 2; // Nhân đôi điểm nếu kích hoạt Ngôi Sao Hy Vọng
    }

    // Cập nhật điểm cho bản ghi dự đoán
    await this.prisma.prediction.update({
      where: { id: predictionId },
      data: {
        pointsEarned: points,
        isCalculated: true,
      },
    });

    // Cộng điểm tích lũy vào tài khoản tổng của User
    await this.prisma.user.update({
      where: { id: prediction.userId },
      data: {
        totalPoints: {
          increment: points,
        },
      },
    });

    return points;
  }
}
