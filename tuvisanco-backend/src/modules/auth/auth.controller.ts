import { Controller, Post, Headers, Body, UnauthorizedException } from '@nestjs/common';
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

  @Post('verify-google') // API: http://localhost:3000/auth/verify-google
  async verifyGoogle(@Headers('authorization') authHeader: string) {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Authorization header is missing or malformed. Format: Bearer <ID_TOKEN>');
    }
    const token = authHeader.split(' ')[1];
    return this.authService.verifyFirebaseToken(token);
  }
}
