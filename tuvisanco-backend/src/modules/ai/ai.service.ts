import { Injectable } from '@nestjs/common';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AiService {
  private ai: GoogleGenerativeAI | null = null;

  constructor(private readonly prisma: PrismaService) {
    const apiKey = process.env.GEMINI_API_KEY;
    // Xử lý loại bỏ dấu ngoặc kép và khoảng trắng dư thừa
    const cleanKey = apiKey?.replace(/["']/g, '').trim();

    if (cleanKey) {
      try {
        this.ai = new GoogleGenerativeAI(cleanKey);
        console.log(`📡 Đã nạp Thiên Cơ AI với Key: ${cleanKey.substring(0, 5)}...`);
      } catch (e) {
        console.error('❌ Khởi tạo AI thất bại:', e);
      }
    } else {
      console.warn('⚠️ CẢNH BÁO: GEMINI_API_KEY chưa được cấu hình trong file .env');
    }
  }

  async predictMatchProbability(matchId: string) {
    const match = await this.prisma.match.findUnique({ where: { id: matchId } });
    if (!match) throw new Error('Match not found');

    if (match.aiWinProb !== null) {
      return { winProb: match.aiWinProb, drawProb: match.aiDrawProb, lossProb: match.aiLossProb, analysis: match.aiAnalysis };
    }

    if (!this.ai) return this.getMockPrediction(match);

    try {
      // ĐÃ SỬA: Đổi về model 1.5-flash chính xác (trước đó là 3.5-flash không tồn tại)
      const model = this.ai.getGenerativeModel({ model: 'gemini-1.5-flash' });
      const prompt = `Phân tích trận đấu: ${match.homeTeam} vs ${match.awayTeam}. Trả về JSON: {"win": số, "draw": số, "loss": số, "analysis": "nhận định tiếng Việt"}`;
      
      const result = await model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();
      const parsed = JSON.parse(text.replace(/```json|```/g, ''));

      return await this.prisma.match.update({
        where: { id: matchId },
        data: {
          aiWinProb: parsed.win,
          aiDrawProb: parsed.draw,
          aiLossProb: parsed.loss,
          aiAnalysis: parsed.analysis,
        },
      });
    } catch (e) {
      console.error('❌ Lỗi Dự đoán AI:', e);
      return this.getMockPrediction(match);
    }
  }

  private getMockPrediction(match: any) {
    return { winProb: 40, drawProb: 30, lossProb: 30, analysis: `Trận đấu ${match.homeTeam} gặp ${match.awayTeam} dự kiến sẽ rất căng thẳng.` };
  }

  async chat(message: string) {
    if (!this.ai) {
      return {
        response: 'Chào đạo hữu! Lão mỗ đang trong quá trình bế quan tu luyện (Chưa nạp được API Key). ' +
                  'Đạo hữu hãy kiểm tra lại file .env xem GEMINI_API_KEY đã đúng chưa nhé!'
      };
    }

    const modelsToTry = [
      'gemini-1.5-flash',
      'gemini-1.5-pro',
      'gemini-3.5-flash',
      'gemini-2.5-flash',
      'gemini-pro',
    ];
    let lastError = '';

    console.log(`🔮 Đang thử giải mã thiên cơ với tin nhắn: "${message}"`);

    for (const modelName of modelsToTry) {
      try {
        const model = this.ai.getGenerativeModel({ model: modelName });
        const chat = model.startChat({
          history: [
            { role: 'user', parts: [{ text: 'Bạn là "Lão Đạo Hữu AI", một đạo sĩ uyên bác về tử vi bóng đá. Xưng "Lão mỗ", gọi người dùng là "đạo hữu". Luôn lái câu chuyện về phong thủy và vận mệnh sân cỏ.' }] },
            { role: 'model', parts: [{ text: 'Lão mỗ đã rõ. Thiên cơ hiển hiện, đạo hữu muốn thỉnh giáo điều chi?' }] },
          ],
        });

        const result = await chat.sendMessage(message);
        const response = await result.response;
        console.log(`✅ Thành công với model: ${modelName}`);
        return { response: response.text() };
      } catch (e: any) {
        lastError = e.message || 'Lỗi không xác định';
        console.error(`❌ Model ${modelName} thất bại:`, lastError);
        continue;
      }
    }

    // Nếu tất cả model đều thất bại
    if (lastError.includes('API key not valid')) {
      return { response: 'Huyền cơ báo rằng: "API Key không hợp lệ". Đạo hữu ơi, cái mã bắt đầu bằng "AQ.Ab..." có vẻ không phải là API Key chính thức của Gemini. Đạo hữu hãy tìm mã bắt đầu bằng "AIza" trong Google AI Studio nhé!' };
    }

    if (lastError.includes('404') || lastError.includes('not found')) {
      return { response: `Huyền cơ báo lỗi 404: Không tìm thấy Model phù hợp. Lỗi chi tiết: ${lastError}. Đạo hữu hãy thử kiểm tra lại vùng (Region) của API Key nhé.` };
    }

    return { response: `Huyền cơ bị lỗi: ${lastError}. Đạo hữu hãy kiểm tra lại Key trong file .env nhé.` };
  }


}
