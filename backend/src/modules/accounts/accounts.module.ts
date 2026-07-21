import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Account } from './domain/entities/account.entity';
import { AccountRepository } from './domain/repositories/account.repository';
import { TypeOrmAccountRepository } from './infrastructure/repositories/account.repository';
import { CreateAccountUseCase } from './application/use-cases/create-account.use-case';
import { UpdateAccountUseCase } from './application/use-cases/update-account.use-case';
import { DeleteAccountUseCase } from './application/use-cases/delete-account.use-case';
import { AccountsController } from './infrastructure/controllers/accounts.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Account])],
  controllers: [AccountsController],
  providers: [
    { provide: AccountRepository, useClass: TypeOrmAccountRepository },
    CreateAccountUseCase,
    UpdateAccountUseCase,
    DeleteAccountUseCase,
  ],
  exports: [AccountRepository],
})
export class AccountsModule {}
