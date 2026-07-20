import { HttpStatus, Injectable } from '@nestjs/common';
import { UserRepository } from '../../domain/repositories/user.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { UpdateProfileDto } from '../../infrastructure/dto/update-profile.dto';
import { toUserProfile, UserProfile } from './get-profile.use-case';

@Injectable()
export class UpdateProfileUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  async execute(userId: string, dto: UpdateProfileDto): Promise<UserProfile> {
    const user = await this.userRepository.findById(userId);
    if (!user || user.deletedAt) {
      throw new AppException(
        HttpStatus.UNAUTHORIZED,
        'UNAUTHORIZED',
        'User no longer exists',
      );
    }

    const updated = await this.userRepository.update(userId, {
      name: dto.name,
      locale: dto.locale,
      defaultCurrency: dto.defaultCurrency,
    });

    return toUserProfile(updated);
  }
}
