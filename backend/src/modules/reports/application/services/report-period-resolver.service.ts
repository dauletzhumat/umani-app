import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException } from '../../../../shared/exceptions/app.exception';

export type ReportPeriod = 'week' | 'month' | 'year' | 'custom';

export interface DateRange {
  dateFrom: string;
  dateTo: string;
}

/** docs/08_API.md §23's `period` query param — week/month/year are
 * calendar-aligned (Monday-of-this-week, 1st-of-this-month,
 * Jan-1-of-this-year) through today; custom takes the client's own
 * dateFrom/dateTo verbatim. */
@Injectable()
export class ReportPeriodResolverService {
  resolve(period: ReportPeriod, dateFrom?: string, dateTo?: string): DateRange {
    if (period === 'custom') {
      if (!dateFrom || !dateTo) {
        throw new AppException(
          HttpStatus.BAD_REQUEST,
          'VALIDATION_ERROR',
          'dateFrom and dateTo are required for period=custom',
          [{ field: 'dateFrom', issue: 'required_for_custom_period' }],
        );
      }
      return { dateFrom, dateTo };
    }

    const today = new Date();
    const todayStr = formatDate(today);

    if (period === 'week') {
      const dayOfWeek = (today.getUTCDay() + 6) % 7; // 0 = Monday
      const monday = new Date(today);
      monday.setUTCDate(today.getUTCDate() - dayOfWeek);
      return { dateFrom: formatDate(monday), dateTo: todayStr };
    }

    if (period === 'month') {
      const firstOfMonth = new Date(
        Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), 1),
      );
      return { dateFrom: formatDate(firstOfMonth), dateTo: todayStr };
    }

    // year
    const firstOfYear = new Date(Date.UTC(today.getUTCFullYear(), 0, 1));
    return { dateFrom: formatDate(firstOfYear), dateTo: todayStr };
  }

  /** The immediately preceding window of the same length — a uniform
   * rule that works for week/month/year/custom alike without needing
   * calendar-aware "previous month" logic (whose month lengths differ). */
  previous(dateFrom: string, dateTo: string): DateRange {
    const from = new Date(`${dateFrom}T00:00:00Z`);
    const to = new Date(`${dateTo}T00:00:00Z`);
    const durationMs = to.getTime() - from.getTime();

    const prevTo = new Date(from.getTime() - 24 * 60 * 60 * 1000);
    const prevFrom = new Date(prevTo.getTime() - durationMs);
    return { dateFrom: formatDate(prevFrom), dateTo: formatDate(prevTo) };
  }
}

function formatDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}
