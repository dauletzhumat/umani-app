import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('installments')
export class Installment {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ type: 'varchar', length: 150 })
  merchant!: string;

  @Column({ name: 'total_amount', type: 'numeric', precision: 18, scale: 2 })
  totalAmount!: string;

  @Column({ name: 'installments_count', type: 'smallint' })
  installmentsCount!: number;

  @Column({ name: 'start_date', type: 'date' })
  startDate!: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  provider!: string | null;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt!: Date | null;
}
