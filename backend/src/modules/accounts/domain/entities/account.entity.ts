import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

export type AccountType = 'cash' | 'bank' | 'card' | 'multi_currency';

@Entity('accounts')
export class Account {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({
    type: 'enum',
    enumName: 'account_type',
    enum: ['cash', 'bank', 'card', 'multi_currency'],
  })
  type!: AccountType;

  @Column({ type: 'varchar', length: 100 })
  name!: string;

  @Column({ type: 'char', length: 3 })
  currency!: string;

  @Column({
    name: 'balance_cached',
    type: 'numeric',
    precision: 18,
    scale: 2,
    default: 0,
  })
  balanceCached!: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  provider!: string | null;

  @Column({ type: 'boolean', default: false })
  archived!: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt!: Date | null;
}
