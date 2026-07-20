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
}
