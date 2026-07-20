import { User } from '../entities/user.entity';

export abstract class UserRepository {
  abstract findActiveByIdentifier(identifier: {
    phone: string | null;
    email: string | null;
  }): Promise<User | null>;
}
