import { Injectable } from '@nestjs/common';
import { AccountRepository } from '../../domain/repositories/account.repository';
import { TransactionRepository } from '../../../transactions/domain/repositories/transaction.repository';

/**
 * Recomputes accounts.balance_cached from scratch (SUM over transaction
 * history) rather than applying incremental deltas — matches
 * docs/06_Architecture.md §9's "balance is never authoritative on the
 * client, always recalculated by the server from transaction history":
 * a full recompute is self-healing and can't drift, at a cost that's
 * negligible for a personal-finance transaction volume.
 */
@Injectable()
export class RecalculateAccountBalanceService {
  constructor(
    private readonly accountRepository: AccountRepository,
    private readonly transactionRepository: TransactionRepository,
  ) {}

  async recalculate(accountId: string): Promise<void> {
    const balance = await this.transactionRepository.sumForAccount(accountId);
    await this.accountRepository.setBalance(accountId, balance);
  }
}
