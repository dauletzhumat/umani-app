import { Account, AccountType } from '../entities/account.entity';

export abstract class AccountRepository {
  /** All non-archived-in-DB (not soft-deleted) accounts owned by the user. */
  abstract findAllForUser(userId: string): Promise<Account[]>;

  abstract findById(id: string): Promise<Account | null>;

  abstract create(data: {
    userId: string;
    type: AccountType;
    name: string;
    currency: string;
  }): Promise<Account>;

  abstract update(
    id: string,
    changes: { name?: string; archived?: boolean },
  ): Promise<Account>;

  abstract softDelete(id: string): Promise<void>;

  /** Persists a recomputed balance_cached — distinct from update() since
   * it's never driven by the PATCH DTO (name/archived), only by
   * RecalculateAccountBalanceService. */
  abstract setBalance(id: string, balance: string): Promise<void>;
}
