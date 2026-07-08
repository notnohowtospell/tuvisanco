import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class LobbiesService {
  constructor(private readonly prisma: PrismaService) {}

  async createLobby(data: { name: string; creatorId: string; matchId: string }) {
    // Tạo mã PIN phòng 6 ký tự ngẫu nhiên
    const code = Math.random().toString(36).substring(2, 8).toUpperCase();
    
    const lobby = await this.prisma.lobby.create({
      data: {
        code,
        name: data.name,
        creatorId: data.creatorId,
        matchId: data.matchId,
      },
    });

    // Tự động thêm người tạo vào làm thành viên phòng
    await this.prisma.lobbyMember.create({
      data: {
        lobbyId: lobby.id,
        userId: data.creatorId,
      },
    });

    return lobby;
  }

  async joinLobby(userId: string, code: string) {
    const lobby = await this.prisma.lobby.findUnique({
      where: { code },
    });

    if (!lobby) {
      throw new NotFoundException('Không tìm thấy phòng dự đoán với mã này');
    }

    // Kiểm tra xem đã là thành viên hay chưa
    const existing = await this.prisma.lobbyMember.findUnique({
      where: {
        lobbyId_userId: {
          lobbyId: lobby.id,
          userId,
        },
      },
    });

    if (!existing) {
      await this.prisma.lobbyMember.create({
        data: {
          lobbyId: lobby.id,
          userId,
        },
      });
    }

    return lobby;
  }

  async getLobbyDetails(code: string) {
    return this.prisma.lobby.findUnique({
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
