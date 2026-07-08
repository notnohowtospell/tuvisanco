import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getLeaderboard() {
    return this.prisma.user.findMany({
      orderBy: { totalPoints: 'desc' },
      take: 50,
      select: {
        id: true,
        fullName: true,
        avatarUrl: true,
        totalPoints: true,
      },
    });
  }

  async getProfile(userId: string) {
    return this.prisma.user.findUnique({
      where: { id: userId },
    });
  }
}
