import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class PredictionsService {
  constructor(private readonly prisma: PrismaService) {}

  async submitPrediction(userId: string, data: { matchId: string; predictedHomeScore: number; predictedAwayScore: number }) {
    // Xác định kết quả dự đoán (NHA, HOA, KHACH) từ tỷ số điền vào
    const outcome = data.predictedHomeScore > data.predictedAwayScore 
      ? 'NHA' 
      : data.predictedHomeScore < data.predictedAwayScore 
        ? 'KHACH' 
        : 'HOA';

    return this.prisma.freePrediction.create({
      data: {
        userId,
        matchId: data.matchId,
        predictedHomeScore: data.predictedHomeScore,
        predictedAwayScore: data.predictedAwayScore,
        predictedOutcome: outcome, // Lưu dạng NHA/HOA/KHACH
      },
    });
  }

  // Thuật toán chấm điểm Dự Đoán Miễn Phí theo tài liệu Use Case:
  // Đúng tỷ số: +25 điểm. Đúng kết quả: +10 điểm. Sai: 0 điểm.
  // Thưởng chuỗi (streak): 3 trận liên tiếp (+5đ), 5 trận liên tiếp (+15đ).
  async calculatePredictionScore(predictionId: string, actualHomeScore: number, actualAwayScore: number) {
    const prediction = await this.prisma.freePrediction.findUnique({ where: { id: predictionId } });
    if (!prediction) return 0;

    let points = 0;
    const predHome = prediction.predictedHomeScore;
    const predAway = prediction.predictedAwayScore;

    // Kết quả thực tế
    const actualOutcome = actualHomeScore > actualAwayScore 
      ? 'NHA' 
      : actualHomeScore < actualAwayScore 
        ? 'KHACH' 
        : 'HOA';
        
    const predOutcome = prediction.predictedOutcome;

    const isExactScore = (predHome === actualHomeScore && predAway === actualAwayScore);
    const isExactOutcome = (predOutcome === actualOutcome);

    if (isExactScore) {
      points = 25; // Trúng tỷ số chính xác nhận 25đ
    } else if (isExactOutcome) {
      points = 10; // Chỉ trúng kết quả Thắng/Hòa/Thua nhận 10đ
    }

    // Cập nhật bản ghi dự đoán
    await this.prisma.freePrediction.update({
      where: { id: predictionId },
      data: {
        pointsEarned: points,
        status: isExactOutcome || isExactScore ? 'CORRECT' : 'INCORRECT',
      },
    });

    // Cộng điểm tích lũy và tính toán chuỗi thắng liên tiếp (streak) cho User
    const user = await this.prisma.user.findUnique({ where: { id: prediction.userId } });
    if (user) {
      let newStreak = user.streakCurrent;
      
      if (points > 0) {
        newStreak += 1;
        // Cộng điểm thưởng chuỗi liên tiếp (Streak)
        if (newStreak === 3) {
          points += 5; // Chuỗi 3 trận: +5 điểm thưởng
        } else if (newStreak === 5) {
          points += 15; // Chuỗi 5 trận: +15 điểm thưởng
        }
      } else {
        newStreak = 0; // Đứt chuỗi nếu dự đoán sai
      }

      const newMaxStreak = Math.max(user.streakMax, newStreak);

      await this.prisma.user.update({
        where: { id: prediction.userId },
        data: {
          totalPoints: {
            increment: points,
          },
          streakCurrent: newStreak,
          streakMax: newMaxStreak,
        },
      });
    }

    return points;
  }
}
