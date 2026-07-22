import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
} from '@nestjs/common';
import { ReceiptScanRepository } from '../../domain/repositories/receipt-scan.repository';
import {
  DraftTransaction,
  ScanReceiptUseCase,
} from '../../application/use-cases/scan-receipt.use-case';
import { CreateScanDto } from '../dto/create-scan.dto';
import { CurrentUser } from '../../../../shared/decorators/current-user.decorator';
import { AppException } from '../../../../shared/exceptions/app.exception';
import type { AccessTokenPayload } from '../../../../shared/types/access-token-payload';

@Controller('ocr')
export class OcrController {
  constructor(
    private readonly scanReceiptUseCase: ScanReceiptUseCase,
    private readonly receiptScanRepository: ReceiptScanRepository,
  ) {}

  @Post('scans')
  @HttpCode(HttpStatus.CREATED)
  create(@CurrentUser() user: AccessTokenPayload, @Body() dto: CreateScanDto) {
    return this.scanReceiptUseCase.execute(user.sub, dto);
  }

  @Get('scans/:id')
  async findOne(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    const scan = await this.receiptScanRepository.findById(id);
    if (!scan || scan.userId !== user.sub) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Scan not found',
      );
    }

    if (scan.status !== 'processed') {
      return { receiptScanId: scan.id, status: scan.status };
    }

    const stored = scan.rawOcrJson as {
      draftTransaction: DraftTransaction;
    } | null;

    return {
      receiptScanId: scan.id,
      status: scan.status,
      draftTransaction: stored?.draftTransaction ?? null,
    };
  }
}
