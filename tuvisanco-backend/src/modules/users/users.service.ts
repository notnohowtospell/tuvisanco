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

  private getVietnamDateStr(date: Date): string {
    return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Ho_Chi_Minh' }).format(date);
  }

  // LẤY TRẠNG THÁI ĐIỂM DANH
  async getCheckInStatus(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new Error('Không tìm thấy người dùng.');
    }

    const now = new Date();
    const nowVnStr = this.getVietnamDateStr(now);
    
    let canCheckInToday = true;
    let activeStreak = user.checkInStreak;

    if (user.lastCheckInDateTime) {
      const lastVnStr = this.getVietnamDateStr(user.lastCheckInDateTime);
      if (nowVnStr === lastVnStr) {
        canCheckInToday = false;
      }

      // Kiểm tra chuỗi liên tiếp (liệu hôm qua có điểm danh không)
      const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      const yesterdayVnStr = this.getVietnamDateStr(yesterday);

      const isConsecutive = (lastVnStr === yesterdayVnStr || lastVnStr === nowVnStr);
      if (!isConsecutive) {
        activeStreak = 0; // Đứt chuỗi
      }
    } else {
      activeStreak = 0;
    }

    const isCheckedToday = !canCheckInToday;
    // Nếu hôm qua đã điểm danh ngày 7, hôm nay mở app sẽ hiện ngày 1 sẵn sàng điểm danh
    if (!isCheckedToday && activeStreak === 7) {
      activeStreak = 0;
    }

    const history = [];
    for (let i = 1; i <= 7; i++) {
      let status: 'claimed' | 'today' | 'locked' = 'locked';
      if (i <= activeStreak) {
        status = 'claimed';
      } else if (i === activeStreak + 1 && !isCheckedToday) {
        status = 'today';
      }
      history.push({
        dayIndex: i,
        points: i === 7 ? 100 : 50,
        status,
      });
    }

    return {
      canCheckInToday,
      currentStreak: activeStreak,
      history,
      totalPoints: user.totalPoints,
    };
  }

  // THỰC HIỆN ĐIỂM DANH
  async checkIn(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new Error('Không tìm thấy người dùng.');
    }

    const now = new Date();
    const nowVnStr = this.getVietnamDateStr(now);

    if (user.lastCheckInDateTime) {
      const lastVnStr = this.getVietnamDateStr(user.lastCheckInDateTime);
      if (nowVnStr === lastVnStr) {
        throw new Error('Bạn đã điểm danh hôm nay rồi. Vui lòng quay lại vào ngày mai!');
      }
    }

    let newStreak = 1;
    if (user.lastCheckInDateTime) {
      const lastVnStr = this.getVietnamDateStr(user.lastCheckInDateTime);
      const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      const yesterdayVnStr = this.getVietnamDateStr(yesterday);

      if (lastVnStr === yesterdayVnStr) {
        newStreak = (user.checkInStreak % 7) + 1;
      }
    }

    const pointsEarned = newStreak === 7 ? 100 : 50;

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        totalPoints: { increment: pointsEarned },
        checkInStreak: newStreak,
        lastCheckInDateTime: now,
      },
    });

    return {
      success: true,
      pointsEarned,
      newStreak,
      totalPoints: updatedUser.totalPoints,
    };
  }
}
