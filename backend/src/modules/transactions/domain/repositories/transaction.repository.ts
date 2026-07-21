import {
  Transaction,
  TransactionSource,
  TransactionType,
} from '../entities/transaction.entity';

export interface TransactionListFilters {
  accountId?: string;
  categoryId?: string;
  type?: TransactionType;
  dateFrom?: string;
  dateTo?: string;
}

export interface TransactionCursor {
  id: string;
  occurredAt: string;
}

export abstract class TransactionRepository {
  /** Keyset-paginated (occurredAt, id) DESC — see list-transactions.use-case.ts. */
  abstract findAllForUser(
    userId: string,
    filters: TransactionListFilters,
    cursor: TransactionCursor | null,
    limit: number,
  ): Promise<{ items: Transaction[]; hasMore: boolean }>;

  abstract findById(id: string): Promise<Transaction | null>;

  abstract create(data: {
    userId: string;
    accountId: string;
    categoryId: string | null;
    amount: string;
    currency: string;
    type: TransactionType;
    source: TransactionSource;
    occurredAt: string;
    note: string | null;
  }): Promise<Transaction>;

  abstract update(
    id: string,
    changes: {
      categoryId?: string | null;
      amount?: string;
      currency?: string;
      type?: TransactionType;
      occurredAt?: string;
      note?: string | null;
    },
  ): Promise<Transaction>;

  abstract softDelete(id: string): Promise<void>;
}
