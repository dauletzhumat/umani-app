import { Module } from '@nestjs/common';
import { RedisModule } from '../../shared/redis/redis.module';
import { CategoriesModule } from '../categories/categories.module';
import { OpenAiClientService } from './infrastructure/services/openai-client.service';
import { CategorizationService } from './infrastructure/services/categorization.service';

@Module({
  imports: [RedisModule, CategoriesModule],
  providers: [OpenAiClientService, CategorizationService],
  exports: [OpenAiClientService, CategorizationService],
})
export class AiModule {}
