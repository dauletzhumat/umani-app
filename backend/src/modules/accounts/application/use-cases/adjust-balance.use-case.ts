import { HttpStatus, Injectable } from '@nestjs/common';
import { AccountRepository } from '../../domain/repositories/account.repository';
import { TransactionRepository } from '../../../transactions/domain/repositories/transaction.repository';
import { Transaction } from '../../../transactions/domain/entities/transaction.entity';
import { RecalculateAccountBalanceService } from '../services/recalculate-account-balance.service';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { AdjustBalanceDto } from '../../infrastructure/dto/adjust-balance.dto';

const DEFAULT_NOTE = 'Сверка баланса';

@Injectable()
export class AdjustBalanceUseCase {
  constructor(
    private readonly accountRepository: AccountRepository,
    private readonly transactionRepository: TransactionRepository,
    private readonly recalculateAccountBalanceService: RecalculateAccountBalanceService,
  ) {}

  async execute(
    userId: string,
    accountId: string,
    dto: AdjustBalanceDto,
  ): Promise<Transaction> {
    const account = await this.accountRepository.findById(accountId);
    if (!account || account.userId !== userId) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Account not found',
      );
    }

    const delta = Number(dto.amount);
    if (delta === 0) {
      throw new AppException(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'UNPROCESSABLE_BUSINESS_RULE',
        'amount must not be zero',
      );
    }

    const transaction = await this.transactionRepository.create({
      userId,
      accountId,
      categoryId: null,
      amount: Math.abs(delta).toFixed(2),
      currency: account.currency,
      type: delta > 0 ? 'income' : 'expense',
      source: 'manual',
      occurredAt: new Date().toISOString().slice(0, 10),
      note: dto.note ?? DEFAULT_NOTE,
    });

    await this.recalculateAccountBalanceService.recalculate(accountId);

    return transaction;
  }
}
