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
}
