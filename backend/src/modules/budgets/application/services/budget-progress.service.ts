import { Injectable } from '@nestjs/common';
import { Budget, BudgetPeriod } from '../../domain/entities/budget.entity';
import { TransactionRepository } from '../../../transactions/domain/repositories/transaction.repository';

export interface BudgetProgress {
  id: string;
  categoryId: string;
  categoryName: string;
  amountLimit: string;
  period: BudgetPeriod;
  startDate: string;
  spentAmount: string;
  remainingAmount: string;
  progressPercent: number;
}

/** Computes the fields docs/08_API.md §11 says are "never stored, always
 * derived from transactions" — spentAmount/remainingAmount/progressPercent
 * for a budget's own [startDate, startDate + period) window. */
@Injectable()
export class BudgetProgressService {
  constructor(private readonly transactionRepository: TransactionRepository) {}

  async computeProgress(
    budget: Budget,
    categoryName: string,
  ): Promise<BudgetProgress> {
    const periodEnd = periodEndDate(budget.startDate, budget.period);
    const spentAmount =
      await this.transactionRepository.sumExpenseForCategoryInRange(
        budget.userId,
        budget.categoryId,
        budget.startDate,
        periodEnd,
      );

    return {
      id: budget.id,
      categoryId: budget.categoryId,
      categoryName,
      amountLimit: budget.amountLimit,
      period: budget.period,
      startDate: budget.startDate,
      spentAmount: Number(spentAmount).toFixed(2),
      remainingAmount: (
        Number(budget.amountLimit) - Number(spentAmount)
      ).toFixed(2),
      progressPercent: calculateProgressPercent(
        budget.amountLimit,
        spentAmount,
      ),
    };
  }
}

/** Floored (not rounded — docs/08_API.md §11's worked example pairs
 * spentAmount 56400.00/amountLimit 80000.00 with progressPercent 70,
 * not the round-half-up 71), uncapped — overspending reads as >100%
 * rather than clamping to 100 (the client shows an explicit overspend
 * state). */
export function calculateProgressPercent(
  amountLimit: string,
  spentAmount: string,
): number {
  const limit = Number(amountLimit);
  if (limit <= 0) return 0;
  return Math.floor((Number(spentAmount) / limit) * 100);
}

/** Whether `dateStr` falls in the budget's own [startDate, startDate +
 * period) window — BudgetThresholdListener (T6.2) uses this to narrow a
 * transaction's category down to the budget(s) it actually affects. */
export function isWithinBudgetPeriod(budget: Budget, dateStr: string): boolean {
  const periodEnd = periodEndDate(budget.startDate, budget.period);
  return dateStr >= budget.startDate && dateStr < periodEnd;
}

// JS Date's month rollover (e.g. Jan 31 + 1 month -> Mar 3) is an accepted
// MVP tradeoff — no date library exists in this project yet and budgets
// starting on the 29th-31st are a small edge case.
function periodEndDate(startDate: string, period: BudgetPeriod): string {
  const end = new Date(`${startDate}T00:00:00Z`);
  if (period === 'weekly') {
    end.setUTCDate(end.getUTCDate() + 7);
  } else {
    end.setUTCMonth(end.getUTCMonth() + 1);
  }
  return end.toISOString().slice(0, 10);
}
