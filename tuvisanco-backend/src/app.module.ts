import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
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
    ConfigModule.forRoot({ isGlobal: true }), // Để load file .env cho toàn bộ App
    ScheduleModule.forRoot(), // Kích hoạt tính năng tự động cập nhật Thiên Cơ
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
