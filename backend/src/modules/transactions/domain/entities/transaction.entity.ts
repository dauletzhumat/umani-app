import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

export type TransactionType = 'income' | 'expense';
export type TransactionSource = 'manual' | 'ocr' | 'voice' | 'import';

@Entity('transactions')
export class Transaction {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  // Denormalized from account_id -> accounts.user_id (docs/07_Database.md
  // §5.7): most queries are "all of this user's operations across every
  // account", so this avoids a JOIN on the hot path.
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ name: 'account_id', type: 'uuid' })
  accountId!: string;

  @Column({ name: 'category_id', type: 'uuid', nullable: true })
  categoryId!: string | null;

  @Column({ name: 'receipt_scan_id', type: 'uuid', nullable: true })
  receiptScanId!: string | null;

  @Column({ type: 'numeric', precision: 18, scale: 2 })
  amount!: string;

  @Column({ type: 'char', length: 3 })
  currency!: string;

  @Column({
    type: 'enum',
    enumName: 'transaction_type',
    enum: ['income', 'expense'],
  })
  type!: TransactionType;

  @Column({
    type: 'enum',
    enumName: 'transaction_source',
    enum: ['manual', 'ocr', 'voice', 'import'],
    default: 'manual',
  })
  source!: TransactionSource;

  @Column({ name: 'occurred_at', type: 'date' })
  occurredAt!: string;

  @Column({ type: 'varchar', length: 500, nullable: true })
  note!: string | null;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt!: Date | null;
}
