import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios'; // Nhớ dòng import này
import { MatchesService } from './matches.service';
import { MatchesController } from './matches.controller';

@Module({
  imports: [HttpModule], // Thêm HttpModule vào đây để dùng được HttpService gọi API
  controllers: [MatchesController],
  providers: [MatchesService],
  exports: [MatchesService],
})
export class MatchesModule {}