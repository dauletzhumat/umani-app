import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Account } from './domain/entities/account.entity';
import { AccountRepository } from './domain/repositories/account.repository';
import { TypeOrmAccountRepository } from './infrastructure/repositories/account.repository';
import { CreateAccountUseCase } from './application/use-cases/create-account.use-case';
import { UpdateAccountUseCase } from './application/use-cases/update-account.use-case';
import { DeleteAccountUseCase } from './application/use-cases/delete-account.use-case';
import { RecalculateAccountBalanceService } from './application/services/recalculate-account-balance.service';
import { AccountsController } from './infrastructure/controllers/accounts.controller';
import { Transaction } from '../transactions/domain/entities/transaction.entity';
import { TransactionRepository } from '../transactions/domain/repositories/transaction.repository';
import { TypeOrmTransactionRepository } from '../transactions/infrastructure/repositories/transaction.repository';

@Module({
  // Transaction/TransactionRepository are bound here too (alongside
  // TransactionsModule's own identical binding) so RecalculateAccountBalanceService
  // and T4.3's adjust-balance use-case can depend on TransactionRepository
  // without a circular module import — TransactionsModule already imports
  // AccountsModule the other way for ownership checks.
  imports: [TypeOrmModule.forFeature([Account, Transaction])],
  controllers: [AccountsController],
  providers: [
    { provide: AccountRepository, useClass: TypeOrmAccountRepository },
    { provide: TransactionRepository, useClass: TypeOrmTransactionRepository },
    RecalculateAccountBalanceService,
    CreateAccountUseCase,
    UpdateAccountUseCase,
    DeleteAccountUseCase,
  ],
  exports: [AccountRepository, RecalculateAccountBalanceService],
})
export class AccountsModule {}
