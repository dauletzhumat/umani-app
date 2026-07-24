import { IsIn, IsOptional, Matches } from 'class-validator';
import type { BudgetPeriod } from '../../domain/entities/budget.entity';

const BUDGET_PERIODS = ['weekly', 'monthly'] as const;

/** Limit/period only, per docs/08_API.md §11 — startDate isn't editable. */
export class UpdateBudgetDto {
  @IsOptional()
  @Matches(/^\d+(\.\d{1,2})?$/, {
    message: 'amountLimit must be a non-negative decimal string',
  })
  amountLimit?: string;

  @IsOptional()
  @IsIn(BUDGET_PERIODS)
  period?: BudgetPeriod;
}
