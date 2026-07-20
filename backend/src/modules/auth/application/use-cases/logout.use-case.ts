import { Injectable } from '@nestjs/common';
import { RefreshTokenRepository } from '../../domain/repositories/refresh-token.repository';
import { hashToken } from '../../../../shared/utils/hash-token';

@Injectable()
export class LogoutUseCase {
  constructor(
    private readonly refreshTokenRepository: RefreshTokenRepository,
  ) {}

  /**
   * Revokes one specific session. Idempotent by design (no error if the
   * token is unknown or belongs to someone else) — logout shouldn't leak
   * whether a given refresh token exists or who it belongs to.
   */
  async logout(userId: string, refreshToken: string): Promise<void> {
    const stored = await this.refreshTokenRepository.findByHash(
      hashToken(refreshToken),
    );
    if (stored && stored.userId === userId) {
      await this.refreshTokenRepository.revoke(stored.id);
    }
  }

  async logoutAll(userId: string): Promise<void> {
    await this.refreshTokenRepository.revokeAllForUser(userId);
  }
}
