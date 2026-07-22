import { ReceiptScan } from '../entities/receipt-scan.entity';

export abstract class ReceiptScanRepository {
  abstract create(data: {
    userId: string;
    imageUrl: string;
  }): Promise<ReceiptScan>;

  abstract findById(id: string): Promise<ReceiptScan | null>;

  abstract markProcessed(
    id: string,
    rawOcrJson: Record<string, unknown>,
  ): Promise<ReceiptScan>;

  abstract markFailed(id: string): Promise<ReceiptScan>;
}
