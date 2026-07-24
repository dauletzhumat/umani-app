import { InstallmentPayment } from '../entities/installment-payment.entity';

export abstract class InstallmentPaymentRepository {
  abstract createMany(
    installmentId: string,
    payments: Array<{ dueDate: string; amount: string }>,
  ): Promise<InstallmentPayment[]>;

  /** All payments across a batch of installments — used to compute
   * totalOutstanding and each installment's nextPayment in one query
   * instead of N+1 (T7.2's GET /installments). */
  abstract findAllForInstallments(
    installmentIds: string[],
  ): Promise<InstallmentPayment[]>;
}
