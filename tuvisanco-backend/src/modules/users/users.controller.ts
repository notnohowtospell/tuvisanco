import { Controller, Get, Post, Body, Param } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('leaderboard')
  async getLeaderboard() {
    return this.usersService.getLeaderboard();
  }

  @Get('check-in-status/:userId')
  async getCheckInStatus(@Param('userId') userId: string) {
    return this.usersService.getCheckInStatus(userId);
  }

  @Post('check-in')
  async checkIn(@Body() body: { userId: string }) {
    return this.usersService.checkIn(body.userId);
  }

  @Get(':id')
  async getProfile(@Param('id') id: string) {
    return this.usersService.getProfile(id);
  }
}
