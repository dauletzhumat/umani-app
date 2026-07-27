import { Injectable } from '@nestjs/common';
import { ReportsRepository } from '../../domain/repositories/reports.repository';
import { CategoryRepository } from '../../../categories/domain/repositories/category.repository';
import { ReportPeriodResolverService } from '../services/report-period-resolver.service';
import { ReportsQueryDto } from '../../infrastructure/dto/reports-query.dto';

const UNCATEGORIZED_LABEL = 'Без категории';

export interface CategoryBreakdown {
  categoryId: string | null;
  categoryName: string;
  amount: string;
  percentage: number;
}

export interface ByCategoryReport {
  period: string;
  dateFrom: string;
  dateTo: string;
  totalExpense: string;
  categories: CategoryBreakdown[];
}

@Injectable()
export class GetByCategoryUseCase {
  constructor(
    private readonly reportsRepository: ReportsRepository,
    private readonly categoryRepository: CategoryRepository,
    private readonly reportPeriodResolverService: ReportPeriodResolverService,
  ) {}

  async execute(
    userId: string,
    dto: ReportsQueryDto,
  ): Promise<ByCategoryReport> {
    const period = dto.period ?? 'month';
    const { dateFrom, dateTo } = this.reportPeriodResolverService.resolve(
      period,
      dto.dateFrom,
      dto.dateTo,
    );

    const rows = await this.reportsRepository.sumExpenseByCategory(
      userId,
      dateFrom,
      dateTo,
    );
    const totalExpense = rows.reduce((sum, row) => sum + Number(row.amount), 0);

    const categories = await Promise.all(
      rows.map(async (row) => {
        const category = row.categoryId
          ? await this.categoryRepository.findById(row.categoryId)
          : null;

        return {
          categoryId: row.categoryId,
          categoryName: category?.name ?? UNCATEGORIZED_LABEL,
          amount: Number(row.amount).toFixed(2),
          percentage:
            totalExpense > 0
              ? Math.round((Number(row.amount) / totalExpense) * 100)
              : 0,
        };
      }),
    );

    categories.sort((a, b) => Number(b.amount) - Number(a.amount));

    return {
      period,
      dateFrom,
      dateTo,
      totalExpense: totalExpense.toFixed(2),
      categories,
    };
  }
}
