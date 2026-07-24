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

  abstract findById(id: string): Promise<Installment | null>;

  /** Batch lookup — InstallmentReminderJob (T7.3) resolves userId/merchant
   * for a set of due payments without an N+1 query per payment. */
  abstract findByIds(ids: string[]): Promise<Installment[]>;
}
