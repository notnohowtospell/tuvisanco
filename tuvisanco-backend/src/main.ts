import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 1. THÊM BẮT BUỘC: Bật CORS để cho phép các thiết bị ngoại vi (như máy ảo, máy thật) kết nối vào API
  app.enableCors();

  // 2. SỬA BẮT BUỘC: Ép NestJS lắng nghe trên tất cả các giao diện mạng ('0.0.0.0')
  const port = process.env.PORT ?? 3000;
  await app.listen(port, '0.0.0.0');

  console.log(`🚀 SÂN CỎ BACKEND ĐANG CHẠY TRÊN CỔNG: ${port}`);
  console.log(`👉 Kết nối từ máy ảo Android dùng: http://10.0.2.2:${port}`);
}
bootstrap();