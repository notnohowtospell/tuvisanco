import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth') // Đường dẫn gốc là http://localhost:3000/auth
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register') // API: http://localhost:3000/auth/register
  async register(@Body() body: any) {
    return this.authService.register(body);
  }

  @Post('login') // API: http://localhost:3000/auth/login
  async login(@Body() body: any) {
    return this.authService.login(body);
  }
}