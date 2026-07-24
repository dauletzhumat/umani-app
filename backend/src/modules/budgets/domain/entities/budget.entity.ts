import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

export type BudgetPeriod = 'weekly' | 'monthly';

@Entity('budgets')
export class Budget {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ name: 'category_id', type: 'uuid' })
  categoryId!: string;

  @Column({ name: 'amount_limit', type: 'numeric', precision: 18, scale: 2 })
  amountLimit!: string;

  @Column({
    type: 'enum',
    enumName: 'budget_period',
    enum: ['weekly', 'monthly'],
    default: 'monthly',
  })
  period!: BudgetPeriod;

  @Column({ name: 'start_date', type: 'date' })
  startDate!: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt!: Date | null;
}
