import { Controller, Post, Headers, UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('verify-google')
  async verifyGoogle(@Headers('authorization') authHeader: string) {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Authorization header is missing or malformed. Format: Bearer <ID_TOKEN>');
    }
    const token = authHeader.split(' ')[1];
    return this.authService.verifyFirebaseToken(token);
  }
}
