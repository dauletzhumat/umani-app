import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface VisionAnnotateResponse {
  responses?: Array<{
    fullTextAnnotation?: { text?: string };
  }>;
}

/**
 * Plain REST calls (API key, not the @google-cloud/vision SDK/service
 * account) — simplest path for MVP, same "optional key, graceful no-op"
 * shape as OpenAiClientService (T4.4). There's no real Google Cloud
 * project or Supabase Storage bucket in this environment, so neither
 * call is ever exercised live — only through fakes in tests.
 */
@Injectable()
export class VisionService {
  private readonly logger = new Logger(VisionService.name);
  private readonly apiKey?: string;
  private readonly supabaseUrl?: string;

  constructor(configService: ConfigService) {
    this.apiKey =
      configService.get<string>('GOOGLE_VISION_API_KEY') || undefined;
    this.supabaseUrl = configService.get<string>('SUPABASE_URL') || undefined;
  }

  get isConfigured(): boolean {
    return Boolean(this.apiKey);
  }

  /** Returns the recognized text, or null if the image couldn't be read
   * (missing/unreachable file, or Vision found no text) — the caller
   * maps that to 422 RECEIPT_UNREADABLE. */
  async extractText(storagePath: string): Promise<string | null> {
    const imageBytes = await this.fetchImage(storagePath);
    if (!imageBytes) return null;

    const response = await fetch(
      `https://vision.googleapis.com/v1/images:annotate?key=${this.apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          requests: [
            {
              image: { content: imageBytes.toString('base64') },
              features: [{ type: 'DOCUMENT_TEXT_DETECTION' }],
            },
          ],
        }),
      },
    );

    if (!response.ok) {
      this.logger.warn(`Vision API returned ${response.status}`);
      return null;
    }

    const json = (await response.json()) as VisionAnnotateResponse;
    const text = json.responses?.[0]?.fullTextAnnotation?.text;
    return text && text.trim().length > 0 ? text : null;
  }

  private async fetchImage(storagePath: string): Promise<Buffer | null> {
    if (!this.supabaseUrl) return null;

    try {
      const response = await fetch(
        `${this.supabaseUrl}/storage/v1/object/public/${storagePath}`,
      );
      if (!response.ok) return null;
      return Buffer.from(await response.arrayBuffer());
    } catch {
      return null;
    }
  }
}
