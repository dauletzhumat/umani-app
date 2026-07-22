import { Inject, Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import type Redis from 'ioredis';
import { REDIS_CLIENT } from '../../../../shared/redis/redis.module';
import { CategoryRepository } from '../../../categories/domain/repositories/category.repository';
import {
  CategorizeCompletion,
  OpenAiClientService,
} from './openai-client.service';
import {
  CATEGORIZE_PROMPT,
  buildCategorizePrompt,
} from '../prompts/categorize.prompt';

const CONFIDENCE_THRESHOLD = 0.5;
const CACHE_TTL_SECONDS = 30 * 24 * 60 * 60; // docs/06_Architecture.md §15

export interface CategorizeParams {
  userId: string;
  merchant: string;
  amount: string;
  currency: string;
}

@Injectable()
export class CategorizationService {
  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    private readonly openAiClient: OpenAiClientService,
    private readonly categoryRepository: CategoryRepository,
  ) {}

  /** Returns a categoryId, or null if nothing was confident enough
   * (docs/10_AI.md §9: confidence < 0.5 stays uncategorized rather than
   * guessing) — never throws on AI/cache failure, since categorization
   * is a nice-to-have, not a precondition for saving a transaction. */
  async categorize(params: CategorizeParams): Promise<string | null> {
    const cacheKey = `ai:categorize:${hashKey(params.merchant, params.amount)}`;
    const cached = await this.redis.get(cacheKey);

    let completion: CategorizeCompletion | null;
    if (cached !== null) {
      completion = JSON.parse(cached) as CategorizeCompletion;
    } else {
      const categories = await this.categoryRepository.findAllForUser(
        params.userId,
      );
      const prompt = buildCategorizePrompt({
        merchant: params.merchant,
        amount: params.amount,
        currency: params.currency,
        categoryNames: categories.map((category) => category.name),
      });
      completion = await this.openAiClient.categorize(
        prompt,
        CATEGORIZE_PROMPT.model,
        CATEGORIZE_PROMPT.temperature,
      );
      // Only successful completions are cached — a transient AI/network
      // failure shouldn't suppress categorization for this pair for 30 days.
      if (completion) {
        await this.redis.set(
          cacheKey,
          JSON.stringify(completion),
          'EX',
          CACHE_TTL_SECONDS,
        );
      }
    }

    if (!completion || completion.confidence < CONFIDENCE_THRESHOLD) {
      return null;
    }

    const categories = await this.categoryRepository.findAllForUser(
      params.userId,
    );
    const match = categories.find(
      (category) =>
        category.name.toLowerCase() === completion.categoryName.toLowerCase(),
    );
    return match?.id ?? null;
  }
}

function hashKey(merchant: string, amount: string): string {
  return createHash('sha256')
    .update(`${merchant.trim().toLowerCase()}:${amount}`)
    .digest('hex');
}
