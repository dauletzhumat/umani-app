import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Budget } from './domain/entities/budget.entity';
import { BudgetRepository } from './domain/repositories/budget.repository';
import { TypeOrmBudgetRepository } from './infrastructure/repositories/budget.repository';
import { BudgetProgressService } from './application/services/budget-progress.service';
import { CreateBudgetUseCase } from './application/use-cases/create-budget.use-case';
import { GetBudgetsUseCase } from './application/use-cases/get-budgets.use-case';
import { UpdateBudgetUseCase } from './application/use-cases/update-budget.use-case';
import { DeleteBudgetUseCase } from './application/use-cases/delete-budget.use-case';
import { BudgetsController } from './infrastructure/controllers/budgets.controller';
import { CategoriesModule } from '../categories/categories.module';
import { Transaction } from '../transactions/domain/entities/transaction.entity';
import { TransactionRepository } from '../transactions/domain/repositories/transaction.repository';
import { TypeOrmTransactionRepository } from '../transactions/infrastructure/repositories/transaction.repository';

@Module({
  // Transaction/TransactionRepository bound here too (alongside
  // TransactionsModule's own identical binding), same DI shape as
  // AccountsModule — BudgetProgressService needs read access to sum
  // expenses without a circular module import.
  imports: [TypeOrmModule.forFeature([Budget, Transaction]), CategoriesModule],
  controllers: [BudgetsController],
  providers: [
    { provide: BudgetRepository, useClass: TypeOrmBudgetRepository },
    { provide: TransactionRepository, useClass: TypeOrmTransactionRepository },
    BudgetProgressService,
    CreateBudgetUseCase,
    GetBudgetsUseCase,
    UpdateBudgetUseCase,
    DeleteBudgetUseCase,
  ],
  exports: [BudgetRepository],
})
export class BudgetsModule {}
