import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { initializeApp, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { PrismaService } from '../../prisma/prisma.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {
    // Khởi tạo Firebase Admin SDK
    if (getApps().length === 0) {
      try {
        initializeApp(); // Tự động sử dụng Application Default Credentials
      } catch (e) {
        console.warn('Firebase Admin SDK could not initialize: missing environment configuration. Please configure Service Account.');
      }
    }
  }

  // 1. Logic ĐĂNG KÝ (Register)
  async register(body: any) {
    const { email, password, name } = body;

    // Kiểm tra xem email đã tồn tại chưa
    const userExists = await this.prisma.user.findUnique({ where: { email } });
    if (userExists) {
      throw new BadRequestException('Email này đã được sử dụng!');
    }

    // Mã hóa mật khẩu trước khi lưu vào DB
    const hashedPassword = await bcrypt.hash(password, 10);

    // Tạo user mới trong Database
    const newUser = await this.prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        fullName: name || 'Người dùng mới',
      },
    });

    // Trả về thông tin (không kèm mật khẩu)
    const userResponse = { ...newUser };
    delete (userResponse as any).password;

    return { message: 'Đăng ký thành công!', user: userResponse };
  }

  // 2. Logic ĐĂNG NHẬP (Login)
  async login(body: any) {
    const { email, password } = body;

    // Tìm user theo email
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || !user.password) {
      throw new UnauthorizedException('Email hoặc mật khẩu không chính xác!');
    }

    // So sánh mật khẩu
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Email hoặc mật khẩu không chính xác!');
    }

    // Tạo JWT Token chứa thông tin User
    const payload = { userId: user.id, email: user.email };
    const token = this.jwtService.sign(payload);

    return {
      message: 'Đăng nhập thành công!',
      access_token: token,
      user: { id: user.id, email: user.email, name: user.fullName },
    };
  }

  // 3. Logic XÁC THỰC GOOGLE TOKEN (Firebase Auth)
  async verifyFirebaseToken(token: string) {
    try {
      const decodedToken = await getAuth().verifyIdToken(token);
      const email = decodedToken.email;
      
      if (!email) {
        throw new UnauthorizedException('Firebase token does not contain an email');
      }

      const name = decodedToken.name || 'Bóng Thủ Mới';
      const avatarUrl = decodedToken.picture || '';

      // Find or create User in local PostgreSQL database
      let user = await this.prisma.user.findUnique({
        where: { email },
      });

      if (!user) {
        user = await this.prisma.user.create({
          data: {
            email,
            fullName: name,
            avatarUrl,
            role: 'USER',
          },
        });
      }

      return user;
    } catch (error) {
      throw new UnauthorizedException('Invalid Firebase Token: ' + (error as Error).message);
    }
  }
}
