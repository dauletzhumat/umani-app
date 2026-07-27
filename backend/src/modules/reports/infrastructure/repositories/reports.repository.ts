import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Transaction } from '../../../transactions/domain/entities/transaction.entity';
import {
  CategoryAmount,
  ReportsRepository,
  TypeTotals,
} from '../../domain/repositories/reports.repository';

@Injectable()
export class TypeOrmReportsRepository implements ReportsRepository {
  constructor(
    @InjectRepository(Transaction)
    private readonly repository: Repository<Transaction>,
  ) {}

  async sumByType(
    userId: string,
    dateFrom: string,
    dateTo: string,
  ): Promise<TypeTotals> {
    const rows: Array<{ type: 'income' | 'expense'; total: string }> =
      await this.repository.query(
        `SELECT type, COALESCE(SUM(amount), 0) AS total
         FROM transactions
         WHERE user_id = $1 AND occurred_at >= $2 AND occurred_at <= $3
           AND deleted_at IS NULL
         GROUP BY type`,
        [userId, dateFrom, dateTo],
      );

    const totals: TypeTotals = { income: '0', expense: '0' };
    for (const row of rows) {
      totals[row.type] = row.total;
    }
    return totals;
  }

  async sumExpenseByCategory(
    userId: string,
    dateFrom: string,
    dateTo: string,
  ): Promise<CategoryAmount[]> {
    const rows: Array<{ category_id: string | null; total: string }> =
      await this.repository.query(
        `SELECT category_id, COALESCE(SUM(amount), 0) AS total
         FROM transactions
         WHERE user_id = $1 AND type = 'expense'
           AND occurred_at >= $2 AND occurred_at <= $3
           AND deleted_at IS NULL
         GROUP BY category_id`,
        [userId, dateFrom, dateTo],
      );

    return rows.map((row) => ({
      categoryId: row.category_id,
      amount: row.total,
    }));
  }
}
