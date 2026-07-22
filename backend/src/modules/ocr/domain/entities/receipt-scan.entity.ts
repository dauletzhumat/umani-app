import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

export type ReceiptScanStatus = 'pending' | 'processed' | 'failed';

@Entity('receipt_scans')
export class ReceiptScan {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ name: 'image_url', type: 'text' })
  imageUrl!: string;

  @Column({ name: 'raw_ocr_json', type: 'jsonb', nullable: true })
  rawOcrJson!: Record<string, unknown> | null;

  @Column({ type: 'varchar', length: 20, default: 'pending' })
  status!: ReceiptScanStatus;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
