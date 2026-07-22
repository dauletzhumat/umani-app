import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ReceiptScan } from '../../domain/entities/receipt-scan.entity';
import { ReceiptScanRepository } from '../../domain/repositories/receipt-scan.repository';

@Injectable()
export class TypeOrmReceiptScanRepository implements ReceiptScanRepository {
  constructor(
    @InjectRepository(ReceiptScan)
    private readonly repository: Repository<ReceiptScan>,
  ) {}

  create(data: { userId: string; imageUrl: string }): Promise<ReceiptScan> {
    return this.repository.save({
      userId: data.userId,
      imageUrl: data.imageUrl,
      status: 'pending',
    });
  }

  findById(id: string): Promise<ReceiptScan | null> {
    return this.repository.findOne({ where: { id } });
  }

  async markProcessed(
    id: string,
    rawOcrJson: Record<string, unknown>,
  ): Promise<ReceiptScan> {
    const scan = await this.getOrThrow(id);
    scan.status = 'processed';
    scan.rawOcrJson = rawOcrJson;
    return this.repository.save(scan);
  }

  async markFailed(id: string): Promise<ReceiptScan> {
    const scan = await this.getOrThrow(id);
    scan.status = 'failed';
    return this.repository.save(scan);
  }

  private async getOrThrow(id: string): Promise<ReceiptScan> {
    const scan = await this.repository.findOne({ where: { id } });
    if (!scan) {
      throw new Error('ReceiptScan disappeared during update');
    }
    return scan;
  }
}
