import { Injectable } from '@nestjs/common';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AiService {
  private ai: GoogleGenerativeAI | null = null;

  constructor(private readonly prisma: PrismaService) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (apiKey && apiKey !== 'your_google_gemini_api_key') {
      try {
        this.ai = new GoogleGenerativeAI(apiKey);
      } catch (e) {
        console.error('Failed to initialize Google Gemini AI SDK:', e);
      }
    }
  }

  async predictMatchProbability(matchId: string) {
    const match = await this.prisma.match.findUnique({ where: { id: matchId } });
    if (!match) throw new Error('Match not found');

    // Nếu đã phân tích rồi thì trả về luôn từ cache DB
    if (match.aiWinProb !== null) {
      return {
        winProb: match.aiWinProb,
        drawProb: match.aiDrawProb,
        lossProb: match.aiLossProb,
        analysis: match.aiAnalysis,
      };
    }

    // Nếu chưa có key thì trả về Mock phục vụ quá trình làm lab local của sinh viên
    if (!this.ai) {
      const mockResult = {
        winProb: 45.0,
        drawProb: 30.0,
        lossProb: 25.0,
        analysis: `[Mock AI - Chưa có API Key] Trận đấu giữa ${match.homeTeam} và ${match.awayTeam} dự báo lợi thế thuộc về chủ nhà do ưu thế sân bãi và chuỗi 3 trận thắng liên tiếp vừa qua. Dự đoán tỷ số khả quan là 2-1.`,
      };
      
      await this.prisma.match.update({
        where: { id: matchId },
        data: {
          aiWinProb: mockResult.winProb,
          aiDrawProb: mockResult.drawProb,
          aiLossProb: mockResult.lossProb,
          aiAnalysis: mockResult.analysis,
        },
      });
      
      return mockResult;
    }

    try {
      const model = this.ai.getGenerativeModel({ model: 'gemini-1.5-flash' });
      const prompt = `Phân tích trận đấu bóng đá: ${match.homeTeam} gặp ${match.awayTeam}. Đưa ra tỉ lệ phần trăm thắng của chủ nhà, hòa, và khách dưới dạng số (tổng là 100). Sau đó viết 1 đoạn nhận định tiếng Việt ngắn gọn (dưới 100 từ). Trả về dạng JSON chuẩn có cấu trúc: {"win": số, "draw": số, "loss": số, "analysis": "nhận định"}`;
      
      const result = await model.generateContent(prompt);
      const responseText = result.response.text();
      const cleanJson = responseText.substring(responseText.indexOf('{'), responseText.lastIndexOf('}') + 1);
      const parsed = JSON.parse(cleanJson);

      const updateData = {
        aiWinProb: parseFloat(parsed.win) || 33.3,
        aiDrawProb: parseFloat(parsed.draw) || 33.3,
        aiLossProb: parseFloat(parsed.loss) || 33.3,
        aiAnalysis: parsed.analysis || 'Không có nhận định.',
      };

      await this.prisma.match.update({
        where: { id: matchId },
        data: updateData,
      });

      return updateData;
    } catch (e) {
      console.error('Gemini API Error, falling back to mock:', e);
      return { winProb: 33.3, drawProb: 33.3, lossProb: 33.3, analysis: 'Lỗi kết nối hoặc phân tích Gemini AI. Vui lòng kiểm tra lại key cấu hình.' };
    }
  }
}
