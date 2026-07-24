import { Budget, BudgetPeriod } from '../entities/budget.entity';

export abstract class BudgetRepository {
  /** Non-soft-deleted budgets owned by the user. */
  abstract findAllForUser(userId: string): Promise<Budget[]>;

  abstract findById(id: string): Promise<Budget | null>;

  /** Used for the uq_budgets_user_category_period pre-check (a friendlier
   * 409 CONFLICT message than surfacing the raw DB constraint error). */
  abstract findByUserCategoryPeriodAndStart(
    userId: string,
    categoryId: string,
    period: BudgetPeriod,
    startDate: string,
  ): Promise<Budget | null>;

  abstract create(data: {
    userId: string;
    categoryId: string;
    amountLimit: string;
    period: BudgetPeriod;
    startDate: string;
  }): Promise<Budget>;

  abstract update(
    id: string,
    changes: { amountLimit?: string; period?: BudgetPeriod },
  ): Promise<Budget>;

  abstract softDelete(id: string): Promise<void>;
}
