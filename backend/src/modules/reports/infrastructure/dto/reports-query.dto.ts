import { IsDateString, IsIn, IsOptional } from 'class-validator';
import type { ReportPeriod } from '../../application/services/report-period-resolver.service';

const REPORT_PERIODS = ['week', 'month', 'year', 'custom'] as const;

export class ReportsQueryDto {
  @IsOptional()
  @IsIn(REPORT_PERIODS)
  period?: ReportPeriod;

  @IsOptional()
  @IsDateString()
  dateFrom?: string;

  @IsOptional()
  @IsDateString()
  dateTo?: string;
}
