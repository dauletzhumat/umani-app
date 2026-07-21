import { Injectable } from '@nestjs/common';
import {
  TransactionCursor,
  TransactionListFilters,
  TransactionRepository,
} from '../../domain/repositories/transaction.repository';
import { Transaction } from '../../domain/entities/transaction.entity';
import { PaginatedResult } from '../../../../shared/types/paginated-result';
import { ListTransactionsDto } from '../../infrastructure/dto/list-transactions.dto';

const DEFAULT_LIMIT = 20;

@Injectable()
export class ListTransactionsUseCase {
  constructor(private readonly transactionRepository: TransactionRepository) {}

  async execute(
    userId: string,
    dto: ListTransactionsDto,
  ): Promise<PaginatedResult<Transaction>> {
    const limit = dto.limit ?? DEFAULT_LIMIT;
    const cursor = decodeCursor(dto.cursor);

    const filters: TransactionListFilters = {
      accountId: dto.accountId,
      categoryId: dto.categoryId,
      type: dto.type,
      dateFrom: dto.dateFrom,
      dateTo: dto.dateTo,
    };

    const { items, hasMore } = await this.transactionRepository.findAllForUser(
      userId,
      filters,
      cursor,
      limit,
    );

    return {
      data: items,
      meta: {
        nextCursor: hasMore ? encodeCursor(items[items.length - 1]) : null,
        hasMore,
        limit,
      },
    };
  }
}

/** Malformed cursors are treated as "no cursor" rather than erroring —
 * the client never constructs one itself (docs/08_API.md §4: opaque). */
function decodeCursor(cursor?: string): TransactionCursor | null {
  if (!cursor) return null;
  try {
    const decoded = JSON.parse(
      Buffer.from(cursor, 'base64').toString('utf8'),
    ) as Partial<TransactionCursor>;
    if (
      typeof decoded.id !== 'string' ||
      typeof decoded.occurredAt !== 'string'
    ) {
      return null;
    }
    return { id: decoded.id, occurredAt: decoded.occurredAt };
  } catch {
    return null;
  }
}

function encodeCursor(transaction: Transaction): string {
  const cursor: TransactionCursor = {
    id: transaction.id,
    occurredAt: transaction.occurredAt,
  };
  return Buffer.from(JSON.stringify(cursor), 'utf8').toString('base64');
}
