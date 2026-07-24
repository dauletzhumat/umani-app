import { Injectable } from '@nestjs/common';

export interface GeneratedPayment {
  dueDate: string;
  amount: string;
}

/** Splits totalAmount into installmentsCount equal payments, one per
 * month starting on startDate itself (dueDate[0] = startDate). Integer
 * cents arithmetic (not float division) so the generated amounts always
 * sum to exactly totalAmount — the remainder from flooring each of the
 * first N-1 payments is absorbed entirely by the last one. */
@Injectable()
export class PaymentScheduleGeneratorService {
  generate(params: {
    totalAmount: string;
    installmentsCount: number;
    startDate: string;
  }): GeneratedPayment[] {
    const { totalAmount, installmentsCount, startDate } = params;

    const totalCents = Math.round(Number(totalAmount) * 100);
    const baseCents = Math.floor(totalCents / installmentsCount);
    const lastCents = totalCents - baseCents * (installmentsCount - 1);

    const payments: GeneratedPayment[] = [];
    for (let i = 0; i < installmentsCount; i++) {
      const cents = i === installmentsCount - 1 ? lastCents : baseCents;
      payments.push({
        dueDate: addMonths(startDate, i),
        amount: (cents / 100).toFixed(2),
      });
    }
    return payments;
  }
}

// Same JS Date month-rollover tradeoff as BudgetProgressService's
// periodEndDate — no date library in this project yet.
function addMonths(dateStr: string, months: number): string {
  const date = new Date(`${dateStr}T00:00:00Z`);
  date.setUTCMonth(date.getUTCMonth() + months);
  return date.toISOString().slice(0, 10);
}
