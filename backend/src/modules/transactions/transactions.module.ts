import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Transaction } from './domain/entities/transaction.entity';
import { TransactionRepository } from './domain/repositories/transaction.repository';
import { TypeOrmTransactionRepository } from './infrastructure/repositories/transaction.repository';
import { CreateTransactionUseCase } from './application/use-cases/create-transaction.use-case';
import { ListTransactionsUseCase } from './application/use-cases/list-transactions.use-case';
import { UpdateTransactionUseCase } from './application/use-cases/update-transaction.use-case';
import { DeleteTransactionUseCase } from './application/use-cases/delete-transaction.use-case';
import { TransactionsController } from './infrastructure/controllers/transactions.controller';
import { AccountsModule } from '../accounts/accounts.module';
import { CategoriesModule } from '../categories/categories.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Transaction]),
    AccountsModule,
    CategoriesModule,
  ],
  controllers: [TransactionsController],
  providers: [
    { provide: TransactionRepository, useClass: TypeOrmTransactionRepository },
    CreateTransactionUseCase,
    ListTransactionsUseCase,
    UpdateTransactionUseCase,
    DeleteTransactionUseCase,
  ],
  exports: [TransactionRepository],
})
export class TransactionsModule {}
