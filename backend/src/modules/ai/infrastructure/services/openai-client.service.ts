import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';

export interface CategorizeCompletion {
  categoryName: string;
  confidence: number;
}

/**
 * Thin wrapper around the OpenAI SDK so CategorizationService can be unit
 * tested against a mock instead of hitting the network, and so a missing
 * API key degrades to "no completion" rather than throwing — there's no
 * real OPENAI_API_KEY available in this environment (dev sandbox), same
 * situation T1.2's OtpSenderService stub was built for.
 */
@Injectable()
export class OpenAiClientService {
  private readonly logger = new Logger(OpenAiClientService.name);
  private readonly client: OpenAI | null;

  constructor(configService: ConfigService) {
    const apiKey = configService.get<string>('OPENAI_API_KEY');
    this.client = apiKey ? new OpenAI({ apiKey }) : null;
  }

  async categorize(
    prompt: string,
    model: string,
    temperature: number,
  ): Promise<CategorizeCompletion | null> {
    if (!this.client) return null;

    const response = await this.client.chat.completions.create({
      model,
      temperature,
      response_format: { type: 'json_object' },
      messages: [{ role: 'user', content: prompt }],
    });

    const content = response.choices[0]?.message?.content;
    if (!content) return null;

    try {
      const parsed = JSON.parse(content) as Partial<CategorizeCompletion>;
      if (
        typeof parsed.categoryName !== 'string' ||
        typeof parsed.confidence !== 'number'
      ) {
        return null;
      }
      return {
        categoryName: parsed.categoryName,
        confidence: parsed.confidence,
      };
    } catch {
      this.logger.warn('OpenAI categorization response was not valid JSON');
      return null;
    }
  }
}
