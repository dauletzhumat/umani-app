import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

export type InstallmentPaymentStatus = 'pending' | 'paid' | 'overdue';

@Entity('installment_payments')
export class InstallmentPayment {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'installment_id', type: 'uuid' })
  installmentId!: string;

  @Column({ name: 'due_date', type: 'date' })
  dueDate!: string;

  @Column({ type: 'numeric', precision: 18, scale: 2 })
  amount!: string;

  @Column({
    type: 'enum',
    enumName: 'installment_payment_status',
    enum: ['pending', 'paid', 'overdue'],
    default: 'pending',
  })
  status!: InstallmentPaymentStatus;

  @Column({ name: 'paid_at', type: 'timestamptz', nullable: true })
  paidAt!: Date | null;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
