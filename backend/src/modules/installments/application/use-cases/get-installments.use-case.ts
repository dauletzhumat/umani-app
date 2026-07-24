import { Injectable } from '@nestjs/common';
import { InstallmentRepository } from '../../domain/repositories/installment.repository';
import { InstallmentPaymentRepository } from '../../domain/repositories/installment-payment.repository';

export interface InstallmentSummary {
  id: string;
  merchant: string;
  totalAmount: string;
  installmentsCount: number;
  provider: string | null;
  nextPayment: { dueDate: string; amount: string } | null;
}

export interface InstallmentsOverview {
  totalOutstanding: string;
  installments: InstallmentSummary[];
}

/** docs/08_API.md §13's GET /installments — the map of all installments
 * plus the summed debt load, computed live from installment_payments
 * (never stored). */
@Injectable()
export class GetInstallmentsUseCase {
  constructor(
    private readonly installmentRepository: InstallmentRepository,
    private readonly installmentPaymentRepository: InstallmentPaymentRepository,
  ) {}

  async execute(userId: string): Promise<InstallmentsOverview> {
    const installments =
      await this.installmentRepository.findAllForUser(userId);
    if (installments.length === 0) {
      return { totalOutstanding: '0.00', installments: [] };
    }

    const payments =
      await this.installmentPaymentRepository.findAllForInstallments(
        installments.map((installment) => installment.id),
      );

    let totalOutstandingCents = 0;
    const summaries = installments.map((installment) => {
      const pending = payments.filter(
        (payment) =>
          payment.installmentId === installment.id &&
          payment.status === 'pending',
      );
      totalOutstandingCents += pending.reduce(
        (sum, payment) => sum + Math.round(Number(payment.amount) * 100),
        0,
      );

      // `payments` is ordered by dueDate ASC (TypeOrmInstallmentPaymentRepository),
      // and filter() preserves that order, so [0] is the soonest pending payment.
      const next = pending[0] ?? null;

      return {
        id: installment.id,
        merchant: installment.merchant,
        totalAmount: installment.totalAmount,
        installmentsCount: installment.installmentsCount,
        provider: installment.provider,
        nextPayment: next
          ? { dueDate: next.dueDate, amount: next.amount }
          : null,
      };
    });

    return {
      totalOutstanding: (totalOutstandingCents / 100).toFixed(2),
      installments: summaries,
    };
  }
}
