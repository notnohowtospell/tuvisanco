import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class LobbiesService {
  constructor(private readonly prisma: PrismaService) {}

  private async ensureUserExists(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user && userId === 'mock-google-user-uuid-1234') {
      await this.prisma.user.create({
        data: {
          id: 'mock-google-user-uuid-1234',
          email: 'google.login@gmail.com',
          fullName: 'Google Member',
          totalPoints: 1000,
        },
      });
    }
  }

  // 1. LẤY DANH SÁCH PHÒNG CỦA USER
  async getUserLobbies(userId: string) {
    return this.prisma.bettingRoom.findMany({
      where: {
        OR: [
          { ownerId: userId },
          { coOwners: { some: { userId } } },
          { members: { some: { userId } } },
        ],
      },
      include: {
        match: true,
        owner: {
          select: { id: true, fullName: true, avatarUrl: true },
        },
        coOwners: {
          include: {
            user: { select: { id: true, fullName: true, avatarUrl: true } },
          },
        },
        members: {
          include: {
            user: { select: { id: true, fullName: true, avatarUrl: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // 2. KHỞI TẠO PHÒNG CƯỢC
  async createLobby(data: {
    name: string;
    creatorId: string;
    matchId: string;
    maxMembers: number;
    contribution: number;
  }) {
    if (data.contribution < 200) {
      throw new BadRequestException('Mức góp vốn tối thiểu để tạo phòng là 200 điểm.');
    }

    await this.ensureUserExists(data.creatorId);

    const user = await this.prisma.user.findUnique({
      where: { id: data.creatorId },
    });

    if (!user || user.totalPoints < data.contribution) {
      throw new BadRequestException('Số dư điểm không đủ để tạo phòng.');
    }

    const code = Math.random().toString(36).substring(2, 8).toUpperCase();

    return this.prisma.$transaction(async (tx) => {
      // Trừ điểm user
      await tx.user.update({
        where: { id: data.creatorId },
        data: { totalPoints: { decrement: data.contribution } },
      });

      // Tạo phòng cược
      const room = await tx.bettingRoom.create({
        data: {
          code,
          name: data.name,
          ownerId: data.creatorId,
          matchId: data.matchId,
          totalPool: data.contribution,
          maxMembers: data.maxMembers,
          status: 'SETUP',
        },
      });

      // Thêm CoOwner đầu tiên (chính là Owner sở hữu 100%)
      await tx.roomCoOwner.create({
        data: {
          roomId: room.id,
          userId: data.creatorId,
          contribution: data.contribution,
          shareRatio: 1.0,
        },
      });

      // Thêm thành viên phòng
      await tx.lobbyMember.create({
        data: {
          roomId: room.id,
          userId: data.creatorId,
        },
      });

      return room;
    });
  }

  // 3. MỜI ĐỒNG CHỦ PHÒNG (Ghi nhận với contribution = 0 để làm Pending Invite)
  async inviteCoOwner(roomId: string, inviteeId: string) {
    const room = await this.prisma.bettingRoom.findUnique({
      where: { id: roomId },
      include: { coOwners: true },
    });

    if (!room) {
      throw new NotFoundException('Không tìm thấy phòng.');
    }

    if (room.coOwners.length >= 6) { // Max 5 co-owners + 1 owner
      throw new BadRequestException('Phòng đã đạt giới hạn tối đa 5 Co-owner.');
    }

    const existing = await this.prisma.roomCoOwner.findUnique({
      where: { roomId_userId: { roomId, userId: inviteeId } },
    });

    if (existing) {
      throw new BadRequestException('Người dùng đã là chủ phòng hoặc đã có lời mời.');
    }

    return this.prisma.roomCoOwner.create({
      data: {
        roomId,
        userId: inviteeId,
        contribution: 0, // 0 biểu thị trạng thái chờ chấp nhận (Pending)
        shareRatio: 0.0,
      },
    });
  }

  // LẤY DANH SÁCH LỜI MỜI CHỜ CHẤP NHẬN CỦA USER
  async getPendingInvitations(userId: string) {
    return this.prisma.roomCoOwner.findMany({
      where: {
        userId,
        contribution: 0,
      },
      include: {
        room: {
          include: {
            owner: { select: { fullName: true } },
            match: true,
          },
        },
      },
    });
  }

  // 4. CHẤP NHẬN LỜI MỜI CO-OWNER & GÓP VỐN
  async acceptCoOwner(roomId: string, userId: string, contribution: number) {
    if (contribution < 200) {
      throw new BadRequestException('Mức góp vốn làm Co-owner tối thiểu là 200 điểm.');
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.totalPoints < contribution) {
      throw new BadRequestException('Số dư điểm không đủ để góp vốn.');
    }

    const invite = await this.prisma.roomCoOwner.findUnique({
      where: { roomId_userId: { roomId, userId } },
    });

    if (!invite || invite.contribution > 0) {
      throw new BadRequestException('Không tìm thấy lời mời hợp lệ hoặc lời mời đã được xử lý.');
    }

    return this.prisma.$transaction(async (tx) => {
      // Trừ điểm Co-owner
      await tx.user.update({
        where: { id: userId },
        data: { totalPoints: { decrement: contribution } },
      });

      // Cập nhật dòng góp vốn của Co-owner
      await tx.roomCoOwner.update({
        where: { roomId_userId: { roomId, userId } },
        data: { contribution },
      });

      // Cập nhật tổng quỹ phòng
      const updatedRoom = await tx.bettingRoom.update({
        where: { id: roomId },
        data: { totalPool: { increment: contribution } },
        include: { coOwners: true },
      });

      // Tính toán lại tỷ lệ sở hữu (shareRatio) của tất cả Co-owners
      const totalPool = updatedRoom.totalPool;
      for (const coOwner of updatedRoom.coOwners) {
        await tx.roomCoOwner.update({
          where: { id: coOwner.id },
          data: { shareRatio: coOwner.contribution / totalPool },
        });
      }

      // Thêm Co-owner vào thành viên phòng nếu chưa có
      const memberExists = await tx.lobbyMember.findUnique({
        where: { roomId_userId: { roomId, userId } },
      });

      if (!memberExists) {
        await tx.lobbyMember.create({
          data: { roomId, userId },
        });
      }

      return updatedRoom;
    });
  }

  // 5. TẠO KÈO CƯỢC TỪ TEMPLATE (ODDS CONFIGURATOR)
  async publishMarket(roomId: string, title: string, category: any, options: any[]) {
    let finalCategory = category;
    if (category === 'FUN_BET') {
      finalCategory = 'FUN';
    }
    const room = await this.prisma.bettingRoom.findUnique({
      where: { id: roomId },
      include: { markets: true },
    });

    if (!room) {
      throw new NotFoundException('Không tìm thấy phòng.');
    }

    if (room.markets.length >= 10) {
      throw new BadRequestException('Số lượng kèo tối đa mỗi phòng là 10.');
    }

    // Tìm tỷ lệ cược lớn nhất để tính Exposure Limit
    let maxOdd = 1.10;
    options.forEach((opt) => {
      if (opt.odd > maxOdd) {
        maxOdd = opt.odd;
      }
    });

    const exposureLimit = Math.floor(room.totalPool / maxOdd);

    // Chuẩn hóa options lưu trữ
    const formattedOptions = options.map((opt) => ({
      id: opt.id,
      label: opt.label,
      odd: opt.odd,
      totalBetPoints: 0,
    }));

    const market = await this.prisma.betMarket.create({
      data: {
        roomId,
        title,
        category: finalCategory,
        options: formattedOptions as any,
        exposureLimit,
        currentExposure: 0,
        status: 'OPEN',
      },
    });

    // Cập nhật trạng thái phòng thành OPEN khi có kèo đầu tiên được xuất bản
    if (room.status === 'SETUP') {
      await this.prisma.bettingRoom.update({
        where: { id: roomId },
        data: { status: 'OPEN' },
      });
    }

    return market;
  }

  // 6. GIA NHẬP PHÒNG BẰNG MÃ PIN (MEMBER)
  async joinLobby(userId: string, code: string) {
    await this.ensureUserExists(userId);
    const room = await this.prisma.bettingRoom.findUnique({
      where: { code },
      include: { members: true },
    });

    if (!room) {
      throw new NotFoundException('Mã mời không chính xác. Không tìm thấy phòng.');
    }

    if (room.members.length >= room.maxMembers) {
      throw new BadRequestException('Phòng đã đạt giới hạn tối đa số thành viên.');
    }

    const existing = await this.prisma.lobbyMember.findUnique({
      where: { roomId_userId: { roomId: room.id, userId } },
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

  // 7. ĐẶT CƯỢC KHÓA ĐIỂM (MEMBER)
  async placeBet(userId: string, roomId: string, marketId: string, optionId: string, points: number) {
    if (points < 10) {
      throw new BadRequestException('Mức đặt cược tối thiểu là 10 điểm.');
    }

    await this.ensureUserExists(userId);
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.totalPoints < points) {
      throw new BadRequestException('Số dư tài khoản không đủ để đặt cược.');
    }

    const market = await this.prisma.betMarket.findUnique({
      where: { id: marketId },
      include: { room: true },
    });

    if (!market || market.status !== 'OPEN') {
      throw new BadRequestException('Kèo cược này đã khóa hoặc đã đóng.');
    }

    // Lấy thông số odd của lựa chọn
    const options = market.options as any[];
    const targetOption = options.find((opt) => opt.id === optionId);
    if (!targetOption) {
      throw new BadRequestException('Lựa chọn không hợp lệ.');
    }

    const odd = targetOption.odd;
    const potentialPayout = Math.floor(points * odd);

    // Kiểm tra Exposure Limit của kèo
    if (market.currentExposure + potentialPayout > market.exposureLimit) {
      throw new BadRequestException('Đặt cược thất bại. Kèo này đã vượt giới hạn cược rủi ro của nhà cái.');
    }

    return this.prisma.$transaction(async (tx) => {
      // 1. Trừ điểm người chơi
      await tx.user.update({
        where: { id: userId },
        data: { totalPoints: { decrement: points } },
      });

      // 2. Cập nhật Exposure trong BetMarket
      const updatedExposure = market.currentExposure + potentialPayout;
      const isLimitReached = updatedExposure >= market.exposureLimit;

      // Cập nhật tổng cược của lựa chọn đó
      const updatedOptions = options.map((opt) => {
        if (opt.id === optionId) {
          return { ...opt, totalBetPoints: (opt.totalBetPoints || 0) + points };
        }
        return opt;
      });

      await tx.betMarket.update({
        where: { id: marketId },
        data: {
          currentExposure: updatedExposure,
          options: updatedOptions as any,
          status: isLimitReached ? 'LOCKED' : 'OPEN', // Tự động khóa kèo khi đạt kịch kim giới hạn
        },
      });

      // 3. Ghi đơn cược PlacedBet
      const placedBet = await tx.placedBet.create({
        data: {
          userId,
          roomId,
          marketId,
          optionId,
          points,
          odd,
          result: 'PENDING',
        },
      });

      return placedBet;
    });
  }

  // 8. SETTLE KÈO VUI THỦ CÔNG (OWNER/CO-OWNER)
  async settleFunMarket(roomId: string, marketId: string, winningOptionId: string) {
    const market = await this.prisma.betMarket.findUnique({
      where: { id: marketId },
      include: { placedBets: true },
    });

    if (!market || market.status === 'SETTLED') {
      throw new BadRequestException('Kèo không tồn tại hoặc đã được quyết toán trước đó.');
    }

    return this.prisma.$transaction(async (tx) => {
      // Cập nhật trạng thái kèo
      await tx.betMarket.update({
        where: { id: marketId },
        data: {
          status: 'SETTLED',
          winningOptionId,
        },
      });

      let totalPayoutOut = 0;

      // Quyết toán cho từng người đặt cược
      for (const bet of market.placedBets) {
        if (bet.optionId === winningOptionId) {
          const payout = Math.floor(bet.points * bet.odd);
          totalPayoutOut += payout;

          // Cập nhật đơn cược trúng
          await tx.placedBet.update({
            where: { id: bet.id },
            data: { result: 'WON', payout },
          });

          // Cộng thưởng vào tài khoản user
          await tx.user.update({
            where: { id: bet.userId },
            data: { totalPoints: { increment: payout } },
          });
        } else {
          // Cập nhật đơn cược thua
          await tx.placedBet.update({
            where: { id: bet.id },
            data: { result: 'LOST', payout: 0 },
          });
        }
      }

      // Khấu trừ số điểm thưởng chi trả khỏi quỹ chung của phòng
      await tx.bettingRoom.update({
        where: { id: roomId },
        data: { totalPool: { decrement: totalPayoutOut } },
      });

      return { success: true, totalPayoutOut };
    });
  }

  // 9. GIẢI TÁN PHÒNG CƯỢC & PHÂN PHỐI LẠI QUỸ CHO CÁC NHÀ CÁI
  async dissolveLobby(roomId: string, ownerId: string) {
    const room = await this.prisma.bettingRoom.findUnique({
      where: { id: roomId },
      include: {
        coOwners: true,
        markets: true,
      },
    });

    if (!room) {
      throw new NotFoundException('Không tìm thấy phòng.');
    }

    if (room.ownerId !== ownerId) {
      throw new BadRequestException('Chỉ chủ phòng chính mới có quyền giải tán phòng.');
    }

    // Ràng buộc: Tất cả các kèo phải ở trạng thái SETTLED
    const hasUnsettled = room.markets.some((m) => m.status !== 'SETTLED');
    if (hasUnsettled) {
      throw new BadRequestException('Không thể giải tán phòng. Vui lòng quyết toán (settle) toàn bộ kèo trước.');
    }

    return this.prisma.$transaction(async (tx) => {
      // Phân chia số điểm còn lại trong quỹ phòng cho các nhà cái dựa theo tỷ lệ sở hữu
      const finalPool = room.totalPool;

      for (const coOwner of room.coOwners) {
        const sharePoints = Math.floor(finalPool * coOwner.shareRatio);

        // Cộng điểm hoàn về cho tài khoản user
        await tx.user.update({
          where: { id: coOwner.userId },
          data: { totalPoints: { increment: sharePoints } },
        });
      }

      // Lưu trữ phòng cược
      const archivedRoom = await tx.bettingRoom.update({
        where: { id: roomId },
        data: { status: 'ARCHIVED' },
      });

      return archivedRoom;
    });
  }

  // 10. LẤY CHI TIẾT PHÒNG
  async getLobbyDetails(code: string) {
    return this.prisma.bettingRoom.findUnique({
      where: { code },
      include: {
        match: true,
        owner: { select: { id: true, fullName: true, avatarUrl: true } },
        coOwners: {
          include: {
            user: { select: { id: true, fullName: true, avatarUrl: true } },
          },
        },
        members: {
          include: {
            user: { select: { id: true, fullName: true, avatarUrl: true } },
          },
        },
        markets: true,
        placedBets: {
          include: {
            user: { select: { id: true, fullName: true } },
          },
        },
      },
    });
  }
}
