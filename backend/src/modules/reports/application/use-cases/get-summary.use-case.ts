import { Injectable } from '@nestjs/common';
import { ReportsRepository } from '../../domain/repositories/reports.repository';
import { ReportPeriodResolverService } from '../services/report-period-resolver.service';
import { ReportsQueryDto } from '../../infrastructure/dto/reports-query.dto';

export interface SummaryReport {
  period: string;
  dateFrom: string;
  dateTo: string;
  totalIncome: string;
  totalExpense: string;
  /** Lets the client render 05_UX.md §6's period-comparison text
   * ("в этом месяце на 15% больше, чем в прошлом") without a second
   * request. */
  previousPeriodTotalExpense: string;
}

@Injectable()
export class GetSummaryUseCase {
  constructor(
    private readonly reportsRepository: ReportsRepository,
    private readonly reportPeriodResolverService: ReportPeriodResolverService,
  ) {}

  async execute(userId: string, dto: ReportsQueryDto): Promise<SummaryReport> {
    const period = dto.period ?? 'month';
    const { dateFrom, dateTo } = this.reportPeriodResolverService.resolve(
      period,
      dto.dateFrom,
      dto.dateTo,
    );
    const previous = this.reportPeriodResolverService.previous(
      dateFrom,
      dateTo,
    );

    const current = await this.reportsRepository.sumByType(
      userId,
      dateFrom,
      dateTo,
    );
    const prev = await this.reportsRepository.sumByType(
      userId,
      previous.dateFrom,
      previous.dateTo,
    );

    return {
      period,
      dateFrom,
      dateTo,
      totalIncome: Number(current.income).toFixed(2),
      totalExpense: Number(current.expense).toFixed(2),
      previousPeriodTotalExpense: Number(prev.expense).toFixed(2),
    };
  }
}
