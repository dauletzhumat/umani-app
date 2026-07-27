import { HttpStatus, Injectable } from '@nestjs/common';
import { UserRepository } from '../../domain/repositories/user.repository';
import { RefreshTokenRepository } from '../../../auth/domain/repositories/refresh-token.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';

// docs/08_API.md §12 mandates a grace period before full erasure but
// doesn't name a length — 30 days, matching the project's other
// retention-style constants (docs/06_Architecture.md's data-retention-
// cleanup job, the 30-day AI categorization cache TTL).
const PURGE_GRACE_PERIOD_DAYS = 30;

export interface DeleteAccountResult {
  scheduledPurgeAt: string;
}

@Injectable()
export class DeleteAccountUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly refreshTokenRepository: RefreshTokenRepository,
  ) {}

  async execute(userId: string): Promise<DeleteAccountResult> {
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new AppException(
        HttpStatus.UNAUTHORIZED,
        'UNAUTHORIZED',
        'User no longer exists',
      );
    }

    // Idempotent: a second call (e.g. the same still-valid access token
    // used twice) returns the original date rather than pushing it out.
    if (user.deletedAt && user.scheduledPurgeAt) {
      return { scheduledPurgeAt: user.scheduledPurgeAt.toISOString() };
    }

    const scheduledPurgeAt = new Date();
    scheduledPurgeAt.setDate(
      scheduledPurgeAt.getDate() + PURGE_GRACE_PERIOD_DAYS,
    );

    await this.userRepository.softDelete(userId, scheduledPurgeAt);
    await this.refreshTokenRepository.revokeAllForUser(userId);

    return { scheduledPurgeAt: scheduledPurgeAt.toISOString() };
  }
}
