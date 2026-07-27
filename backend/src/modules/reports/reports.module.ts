import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Transaction } from '../transactions/domain/entities/transaction.entity';
import { ReportsRepository } from './domain/repositories/reports.repository';
import { TypeOrmReportsRepository } from './infrastructure/repositories/reports.repository';
import { ReportPeriodResolverService } from './application/services/report-period-resolver.service';
import { GetSummaryUseCase } from './application/use-cases/get-summary.use-case';
import { GetByCategoryUseCase } from './application/use-cases/get-by-category.use-case';
import { ReportsController } from './infrastructure/controllers/reports.controller';
import { CategoriesModule } from '../categories/categories.module';

@Module({
  // Transaction bound here (read-only aggregation queries) alongside
  // TransactionsModule's own binding, same DI shape as
  // AccountsModule/BudgetsModule — avoids a circular module import.
  imports: [TypeOrmModule.forFeature([Transaction]), CategoriesModule],
  controllers: [ReportsController],
  providers: [
    { provide: ReportsRepository, useClass: TypeOrmReportsRepository },
    ReportPeriodResolverService,
    GetSummaryUseCase,
    GetByCategoryUseCase,
  ],
})
export class ReportsModule {}
