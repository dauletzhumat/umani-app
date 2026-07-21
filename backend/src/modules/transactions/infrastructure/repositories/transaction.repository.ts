import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import {
  Transaction,
  TransactionSource,
  TransactionType,
} from '../../domain/entities/transaction.entity';
import {
  TransactionCursor,
  TransactionListFilters,
  TransactionRepository,
} from '../../domain/repositories/transaction.repository';

@Injectable()
export class TypeOrmTransactionRepository implements TransactionRepository {
  constructor(
    @InjectRepository(Transaction)
    private readonly repository: Repository<Transaction>,
  ) {}

  async findAllForUser(
    userId: string,
    filters: TransactionListFilters,
    cursor: TransactionCursor | null,
    limit: number,
  ): Promise<{ items: Transaction[]; hasMore: boolean }> {
    const qb = this.repository
      .createQueryBuilder('transaction')
      .where('transaction.userId = :userId', { userId })
      .andWhere('transaction.deletedAt IS NULL');

    if (filters.accountId) {
      qb.andWhere('transaction.accountId = :accountId', {
        accountId: filters.accountId,
      });
    }
    if (filters.categoryId) {
      qb.andWhere('transaction.categoryId = :categoryId', {
        categoryId: filters.categoryId,
      });
    }
    if (filters.type) {
      qb.andWhere('transaction.type = :type', { type: filters.type });
    }
    if (filters.dateFrom) {
      qb.andWhere('transaction.occurredAt >= :dateFrom', {
        dateFrom: filters.dateFrom,
      });
    }
    if (filters.dateTo) {
      qb.andWhere('transaction.occurredAt <= :dateTo', {
        dateTo: filters.dateTo,
      });
    }

    // Keyset pagination: anchors on the last row's own (occurredAt, id)
    // rather than an OFFSET count, so inserting a new transaction between
    // two page requests can neither duplicate nor skip a row.
    if (cursor) {
      qb.andWhere(
        '(transaction.occurredAt, transaction.id) < (:cursorOccurredAt, :cursorId)',
        { cursorOccurredAt: cursor.occurredAt, cursorId: cursor.id },
      );
    }

    qb.orderBy('transaction.occurredAt', 'DESC')
      .addOrderBy('transaction.id', 'DESC')
      .take(limit + 1);

    const rows = await qb.getMany();
    const hasMore = rows.length > limit;

    return { items: hasMore ? rows.slice(0, limit) : rows, hasMore };
  }

  findById(id: string): Promise<Transaction | null> {
    return this.repository.findOne({ where: { id, deletedAt: IsNull() } });
  }

  async sumForAccount(accountId: string): Promise<string> {
    // Raw SQL against known column names, rather than the query builder's
    // alias.property substitution, to keep a CASE expression unambiguous.
    const rows: Array<{ balance: string }> = await this.repository.query(
      `SELECT COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0) AS balance
       FROM transactions
       WHERE account_id = $1 AND deleted_at IS NULL`,
      [accountId],
    );
    return rows[0]?.balance ?? '0';
  }

  create(data: {
    userId: string;
    accountId: string;
    categoryId: string | null;
    amount: string;
    currency: string;
    type: TransactionType;
    source: TransactionSource;
    occurredAt: string;
    note: string | null;
  }): Promise<Transaction> {
    return this.repository.save({
      userId: data.userId,
      accountId: data.accountId,
      categoryId: data.categoryId,
      amount: data.amount,
      currency: data.currency,
      type: data.type,
      source: data.source,
      occurredAt: data.occurredAt,
      note: data.note,
    });
  }

  async update(
    id: string,
    changes: {
      categoryId?: string | null;
      amount?: string;
      currency?: string;
      type?: TransactionType;
      occurredAt?: string;
      note?: string | null;
    },
  ): Promise<Transaction> {
    await this.repository.update({ id }, changes);
    const updated = await this.repository.findOne({ where: { id } });
    if (!updated) {
      throw new Error('Transaction disappeared during update');
    }
    return updated;
  }

  async softDelete(id: string): Promise<void> {
    await this.repository.update({ id }, { deletedAt: new Date() });
  }
}
