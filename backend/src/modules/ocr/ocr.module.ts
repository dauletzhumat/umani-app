import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReceiptScan } from './domain/entities/receipt-scan.entity';
import { ReceiptScanRepository } from './domain/repositories/receipt-scan.repository';
import { TypeOrmReceiptScanRepository } from './infrastructure/repositories/receipt-scan.repository';
import { VisionService } from './infrastructure/services/vision.service';
import { ScanReceiptUseCase } from './application/use-cases/scan-receipt.use-case';
import { OcrController } from './infrastructure/controllers/ocr.controller';
import { AiModule } from '../ai/ai.module';

@Module({
  imports: [TypeOrmModule.forFeature([ReceiptScan]), AiModule],
  controllers: [OcrController],
  providers: [
    { provide: ReceiptScanRepository, useClass: TypeOrmReceiptScanRepository },
    VisionService,
    ScanReceiptUseCase,
  ],
  exports: [ReceiptScanRepository],
})
export class OcrModule {}
