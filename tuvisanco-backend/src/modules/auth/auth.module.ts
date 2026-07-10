import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtModule } from '@nestjs/jwt';
import { PrismaModule } from '../../prisma/prisma.module'; // Đảm bảo đường dẫn này trỏ đúng tới thư mục prisma của bạn

@Module({
  imports: [
    PrismaModule, // Kéo Prisma vào để AuthService có thể lưu/tìm User dưới Database
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'tuvisanco_super_secret_jwt_key_9999!', // Đọc khóa bí mật từ file .env
      signOptions: { expiresIn: '7d' }, // Token có hiệu lực trong 7 ngày
    }),
  ],
  controllers: [AuthController], // Khai báo Cổng nhận request API
  providers: [AuthService],       // Khai báo Nơi xử lý logic Đăng nhập/Đăng ký
  exports: [AuthService],         // Xuất ra ngoài nếu các Module khác (như UsersModule) cần dùng chung
})
export class AuthModule {}
