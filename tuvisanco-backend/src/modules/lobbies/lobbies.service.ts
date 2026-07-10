import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class LobbiesService {
  constructor(private readonly prisma: PrismaService) {}

  async createLobby(data: { name: string; creatorId: string; matchId: string }) {
    // Tạo mã PIN phòng 6 ký tự ngẫu nhiên
    const code = Math.random().toString(36).substring(2, 8).toUpperCase();
    
    const room = await this.prisma.bettingRoom.create({
      data: {
        code,
        name: data.name,
        ownerId: data.creatorId, // Khớp với ownerId trong BettingRoom
        matchId: data.matchId,
        totalPool: 200, // Mức góp vốn tối thiểu khởi đầu
      },
    });

    // Tự động thêm người tạo làm thành viên phòng
    await this.prisma.lobbyMember.create({
      data: {
        roomId: room.id, // Khớp với roomId trong LobbyMember
        userId: data.creatorId,
      },
    });

    return room;
  }

  async joinLobby(userId: string, code: string) {
    const room = await this.prisma.bettingRoom.findUnique({
      where: { code },
    });

    if (!room) {
      throw new NotFoundException('Không tìm thấy phòng dự đoán với mã này');
    }

    // Kiểm tra xem đã là thành viên hay chưa
    const existing = await this.prisma.lobbyMember.findUnique({
      where: {
        roomId_userId: {
          roomId: room.id,
          userId,
        },
      },
    });

    if (!existing) {
      await this.prisma.lobbyMember.create({
        data: {
          roomId: room.id,
          userId,
        },
      });
    }

    return room;
  }

  async getLobbyDetails(code: string) {
    return this.prisma.bettingRoom.findUnique({
      where: { code },
      include: {
        match: true,
        members: {
          include: {
            user: {
              select: {
                id: true,
                fullName: true,
                avatarUrl: true,
              },
            },
          },
          orderBy: {
            pointsInRoom: 'desc',
          },
        },
      },
    });
  }
}
