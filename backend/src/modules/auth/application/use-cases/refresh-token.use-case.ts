import { HttpStatus, Injectable } from '@nestjs/common';
import { UserRepository } from '../../../users/domain/repositories/user.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { hashToken } from '../../../../shared/utils/hash-token';
import { RefreshTokenDto } from '../../infrastructure/dto/refresh-token.dto';
import { RefreshTokenRepository } from '../../domain/repositories/refresh-token.repository';
import {
  TokenIssuerService,
  IssuedTokenPair,
} from '../services/token-issuer.service';

@Injectable()
export class RefreshTokenUseCase {
  constructor(
    private readonly refreshTokenRepository: RefreshTokenRepository,
    private readonly userRepository: UserRepository,
    private readonly tokenIssuerService: TokenIssuerService,
  ) {}

  async execute(dto: RefreshTokenDto): Promise<IssuedTokenPair> {
    const tokenHash = hashToken(dto.refreshToken);
    const stored = await this.refreshTokenRepository.findByHash(tokenHash);

    if (!stored) {
      throw new AppException(
        HttpStatus.UNAUTHORIZED,
        'UNAUTHORIZED',
        'Invalid refresh token',
      );
    }

    if (stored.revokedAt) {
      // Replay of an already-revoked token is a compromise signal —
      // revoke every session this user has (docs/08_API.md §2).
      await this.refreshTokenRepository.revokeAllForUser(stored.userId);
      throw new AppException(
        HttpStatus.UNAUTHORIZED,
        'TOKEN_REVOKED',
        'This refresh token was already used; all sessions have been revoked',
      );
    }

    if (stored.expiresAt.getTime() < Date.now()) {
      throw new AppException(
        HttpStatus.UNAUTHORIZED,
        'TOKEN_EXPIRED',
        'Refresh token has expired',
      );
    }

    const user = await this.userRepository.findById(stored.userId);
    if (!user || user.deletedAt) {
      throw new AppException(
        HttpStatus.UNAUTHORIZED,
        'UNAUTHORIZED',
        'User no longer exists',
      );
    }

    await this.refreshTokenRepository.revoke(stored.id);

    return this.tokenIssuerService.issue(user.id);
  }
}
