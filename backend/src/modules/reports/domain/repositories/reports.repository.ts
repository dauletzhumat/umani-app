export interface TypeTotals {
  income: string;
  expense: string;
}

export interface CategoryAmount {
  categoryId: string | null;
  amount: string;
}

export abstract class ReportsRepository {
  abstract sumByType(
    userId: string,
    dateFrom: string,
    dateTo: string,
  ): Promise<TypeTotals>;

  /** Expense-only — the pie chart is "where the money goes"
   * (docs/05_UX.md §6), not a mix of income and expense. categoryId is
   * null for uncategorized transactions, grouped separately by the
   * caller into "Без категории" rather than being dropped. */
  abstract sumExpenseByCategory(
    userId: string,
    dateFrom: string,
    dateTo: string,
  ): Promise<CategoryAmount[]>;
}
