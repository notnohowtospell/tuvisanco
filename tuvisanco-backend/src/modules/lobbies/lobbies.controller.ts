import { Controller, Post, Body, Get, Param } from '@nestjs/common';
import { LobbiesService } from './lobbies.service';

@Controller('lobbies')
export class LobbiesController {
  constructor(private readonly lobbiesService: LobbiesService) {}

  @Post()
  async createLobby(
    @Body() body: { name: string; creatorId: string; matchId: string }
  ) {
    return this.lobbiesService.createLobby(body);
  }

  @Post('join')
  async joinLobby(
    @Body() body: { userId: string; code: string }
  ) {
    return this.lobbiesService.joinLobby(body.userId, body.code.toUpperCase());
  }

  @Get(':code')
  async getLobbyDetails(@Param('code') code: string) {
    return this.lobbiesService.getLobbyDetails(code.toUpperCase());
  }
}
