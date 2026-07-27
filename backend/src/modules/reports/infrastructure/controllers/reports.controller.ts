import { Controller, Get, Query } from '@nestjs/common';
import { GetSummaryUseCase } from '../../application/use-cases/get-summary.use-case';
import { GetByCategoryUseCase } from '../../application/use-cases/get-by-category.use-case';
import { ReportsQueryDto } from '../dto/reports-query.dto';
import { CurrentUser } from '../../../../shared/decorators/current-user.decorator';
import type { AccessTokenPayload } from '../../../../shared/types/access-token-payload';

@Controller('reports')
export class ReportsController {
  constructor(
    private readonly getSummaryUseCase: GetSummaryUseCase,
    private readonly getByCategoryUseCase: GetByCategoryUseCase,
  ) {}

  @Get('summary')
  getSummary(
    @CurrentUser() user: AccessTokenPayload,
    @Query() query: ReportsQueryDto,
  ) {
    return this.getSummaryUseCase.execute(user.sub, query);
  }

  @Get('by-category')
  getByCategory(
    @CurrentUser() user: AccessTokenPayload,
    @Query() query: ReportsQueryDto,
  ) {
    return this.getByCategoryUseCase.execute(user.sub, query);
  }
}
