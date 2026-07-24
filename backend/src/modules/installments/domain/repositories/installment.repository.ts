import { Installment } from '../entities/installment.entity';

export abstract class InstallmentRepository {
  abstract create(data: {
    userId: string;
    merchant: string;
    totalAmount: string;
    installmentsCount: number;
    startDate: string;
    provider: string | null;
  }): Promise<Installment>;

  /** Non-soft-deleted installments owned by the user. */
  abstract findAllForUser(userId: string): Promise<Installment[]>;
}
