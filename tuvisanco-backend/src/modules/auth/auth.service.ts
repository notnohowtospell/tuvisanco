import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../prisma/prisma.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

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

    // Tạo user mới trong Database (Khớp 100% với schema)
    const newUser = await this.prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        fullName: name || 'Người dùng mới', // Sử dụng fullName thay cho name
      },
    });

    // Trả về thông tin (không kèm mật khẩu)
    const userResponse = newUser as any;
    delete userResponse.password;

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

    // So sánh mật khẩu người dùng nhập với mật khẩu đã mã hóa trong DB
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
}