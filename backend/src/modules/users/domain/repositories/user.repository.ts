import { User } from '../entities/user.entity';

export abstract class UserRepository {
  abstract findActiveByIdentifier(identifier: {
    phone: string | null;
    email: string | null;
  }): Promise<User | null>;

  abstract create(identifier: {
    phone: string | null;
    email: string | null;
  }): Promise<User>;

  abstract findById(id: string): Promise<User | null>;

  /** Inserts with an explicit id — used to upgrade a guest session into a
   * real account under the same sub the guest token already carries. */
  abstract createWithId(
    id: string,
    identifier: { phone: string | null; email: string | null },
  ): Promise<User>;
}
