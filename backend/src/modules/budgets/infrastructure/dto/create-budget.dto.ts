import {
  IsDateString,
  IsIn,
  IsOptional,
  IsUUID,
  Matches,
} from 'class-validator';
import type { BudgetPeriod } from '../../domain/entities/budget.entity';

const BUDGET_PERIODS = ['weekly', 'monthly'] as const;

export class CreateBudgetDto {
  @IsUUID()
  categoryId!: string;

  @Matches(/^\d+(\.\d{1,2})?$/, {
    message: 'amountLimit must be a non-negative decimal string',
  })
  amountLimit!: string;

  @IsOptional()
  @IsIn(BUDGET_PERIODS)
  period?: BudgetPeriod;

  @IsDateString()
  startDate!: string;
}
