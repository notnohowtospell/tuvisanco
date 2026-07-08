import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { MatchesModule } from './modules/matches/matches.module';
import { PredictionsModule } from './modules/predictions/predictions.module';
import { LobbiesModule } from './modules/lobbies/lobbies.module';
import { AiModule } from './modules/ai/ai.module';
import { NewsModule } from './modules/news/news.module';

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    UsersModule,
    MatchesModule,
    PredictionsModule,
    LobbiesModule,
    AiModule,
    NewsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
