import { HttpStatus, Injectable } from '@nestjs/common';
import { ReceiptScanRepository } from '../../domain/repositories/receipt-scan.repository';
import { VisionService } from '../../infrastructure/services/vision.service';
import { OpenAiClientService } from '../../../ai/infrastructure/services/openai-client.service';
import { CategorizationService } from '../../../ai/infrastructure/services/categorization.service';
import {
  buildParseReceiptPrompt,
  PARSE_RECEIPT_PROMPT,
} from '../../infrastructure/prompts/parse-receipt.prompt';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { CreateScanDto } from '../../infrastructure/dto/create-scan.dto';

export interface DraftTransaction {
  merchant: string | null;
  amount: string | null;
  currency: string;
  suggestedCategoryId: string | null;
  lineItems: Array<{ name: string; price: string }>;
}

export interface ScanResult {
  receiptScanId: string;
  status: 'processed';
  draftTransaction: DraftTransaction;
}

@Injectable()
export class ScanReceiptUseCase {
  constructor(
    private readonly receiptScanRepository: ReceiptScanRepository,
    private readonly visionService: VisionService,
    private readonly openAiClient: OpenAiClientService,
    private readonly categorizationService: CategorizationService,
  ) {}

  async execute(userId: string, dto: CreateScanDto): Promise<ScanResult> {
    if (!this.visionService.isConfigured) {
      throw new AppException(
        HttpStatus.SERVICE_UNAVAILABLE,
        'AI_PROVIDER_UNAVAILABLE',
        'OCR provider is not configured',
      );
    }

    const scan = await this.receiptScanRepository.create({
      userId,
      imageUrl: dto.storagePath,
    });

    const rawText = await this.visionService.extractText(dto.storagePath);
    if (!rawText) {
      // No OpenAI call on an empty/unreadable scan (docs/10_AI.md §2):
      // don't spend tokens on input we already know is unusable.
      await this.receiptScanRepository.markFailed(scan.id);
      throw new AppException(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'RECEIPT_UNREADABLE',
        'The receipt image could not be read',
      );
    }

    const parsed = await this.openAiClient.parseReceipt(
      buildParseReceiptPrompt(rawText),
      PARSE_RECEIPT_PROMPT.model,
      PARSE_RECEIPT_PROMPT.temperature,
    );

    const merchant = parsed?.merchant ?? null;
    const amount = parsed?.totalAmount ?? null;
    const currency = parsed?.currency ?? 'KZT';
    const lineItems = parsed?.lineItems ?? [];

    // Reuses T4.4's categorization logic verbatim (docs/10_AI.md §2:
    // "переиспользует ту же логику, что и категоризация ручных
    // транзакций") — only attempted when there's a merchant+amount to
    // categorize from.
    let suggestedCategoryId: string | null = null;
    if (merchant && amount) {
      suggestedCategoryId = await this.categorizationService.categorize({
        userId,
        merchant,
        amount,
        currency,
      });
    }

    const draftTransaction: DraftTransaction = {
      merchant,
      amount,
      currency,
      suggestedCategoryId,
      lineItems,
    };

    await this.receiptScanRepository.markProcessed(scan.id, {
      rawText,
      draftTransaction,
    });

    return { receiptScanId: scan.id, status: 'processed', draftTransaction };
  }
}
