import { Controller, Post, Body, Get, Query, Param, UnauthorizedException } from '@nestjs/common';
import { LobbiesService } from './lobbies.service';

@Controller('lobbies')
export class LobbiesController {
  constructor(private readonly lobbiesService: LobbiesService) {}

  // 1. LẤY DANH SÁCH PHÒNG CỦA USER
  @Get()
  async getUserLobbies(@Query('userId') userId: string) {
    return this.lobbiesService.getUserLobbies(userId);
  }

  // 2. KHỞI TẠO PHÒNG CƯỢC
  @Post('create')
  async createLobby(
    @Body() body: {
      name: string;
      creatorId: string;
      matchId: string;
      maxMembers: number;
      contribution: number;
    }
  ) {
    return this.lobbiesService.createLobby(body);
  }

  // 3. MỜI CO-OWNER
  @Post('invite-co-owner')
  async inviteCoOwner(
    @Body() body: { roomId: string; inviteeId: string }
  ) {
    return this.lobbiesService.inviteCoOwner(body.roomId, body.inviteeId);
  }

  // 4. LẤY LỜI MỜI PENDING CỦA USER
  @Get('pending-invitations/:userId')
  async getPendingInvitations(@Param('userId') userId: string) {
    return this.lobbiesService.getPendingInvitations(userId);
  }

  // 5. CHẤP NHẬN LỜI MỜI CO-OWNER & GÓP VỐN
  @Post('accept-co-owner')
  async acceptCoOwner(
    @Body() body: { roomId: string; userId: string; contribution: number }
  ) {
    return this.lobbiesService.acceptCoOwner(body.roomId, body.userId, body.contribution);
  }

  // 6. TẠO KÈO CƯỢC TỪ TEMPLATE (ODDS CONFIGURATOR)
  @Post('publish-market')
  async publishMarket(
    @Body() body: { roomId: string; title: string; category: string; options: any[] }
  ) {
    return this.lobbiesService.publishMarket(body.roomId, body.title, body.category, body.options);
  }

  // 7. GIA NHẬP PHÒNG BẰNG MÃ PIN (MEMBER)
  @Post('join')
  async joinLobby(
    @Body() body: { userId: string; code: string }
  ) {
    return this.lobbiesService.joinLobby(body.userId, body.code.toUpperCase());
  }

  // 8. ĐẶT CƯỢC KHÓA ĐIỂM (MEMBER)
  @Post('place-bet')
  async placeBet(
    @Body() body: { userId: string; roomId: string; marketId: string; optionId: string; points: number }
  ) {
    return this.lobbiesService.placeBet(
      body.userId,
      body.roomId,
      body.marketId,
      body.optionId,
      body.points
    );
  }

  // 9. SETTLE KÈO VUI THỦ CÔNG
  @Post('settle-fun')
  async settleFunMarket(
    @Body() body: { roomId: string; marketId: string; winningOptionId: string }
  ) {
    return this.lobbiesService.settleFunMarket(body.roomId, body.marketId, body.winningOptionId);
  }

  // 10. GIẢI TÁN PHÒNG CƯỢC
  @Post('dissolve')
  async dissolveLobby(
    @Body() body: { roomId: string; ownerId: string }
  ) {
    return this.lobbiesService.dissolveLobby(body.roomId, body.ownerId);
  }

  // 11. CHI TIẾT PHÒNG THEO CODE
  @Get(':code')
  async getLobbyDetails(@Param('code') code: string) {
    return this.lobbiesService.getLobbyDetails(code.toUpperCase());
  }
}
