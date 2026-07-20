import { HttpStatus, Injectable } from '@nestjs/common';
import { UserRepository } from '../../domain/repositories/user.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { User } from '../../domain/entities/user.entity';

export interface UserProfile {
  id: string;
  phone: string | null;
  email: string | null;
  name: string | null;
  locale: string;
  defaultCurrency: string;
}

export function toUserProfile(user: User): UserProfile {
  return {
    id: user.id,
    phone: user.phone,
    email: user.email,
    name: user.name,
    locale: user.locale,
    defaultCurrency: user.defaultCurrency,
  };
}

@Injectable()
export class GetProfileUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  async execute(userId: string): Promise<UserProfile> {
    const user = await this.userRepository.findById(userId);
    if (!user || user.deletedAt) {
      throw new AppException(
        HttpStatus.UNAUTHORIZED,
        'UNAUTHORIZED',
        'User no longer exists',
      );
    }

    return toUserProfile(user);
  }
}
