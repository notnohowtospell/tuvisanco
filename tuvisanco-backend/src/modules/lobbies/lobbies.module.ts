import { Module } from '@nestjs/common';
import { LobbiesService } from './lobbies.service';
import { LobbiesController } from './lobbies.controller';
import { LobbiesGateway } from './lobbies.gateway';

@Module({
  providers: [LobbiesService, LobbiesGateway],
  controllers: [LobbiesController],
  exports: [LobbiesService, LobbiesGateway],
})
export class LobbiesModule {}
