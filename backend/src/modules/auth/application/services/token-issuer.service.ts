import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { RefreshTokenRepository } from '../../domain/repositories/refresh-token.repository';
import { hashToken } from '../../../../shared/utils/hash-token';
import {
  JwtService,
  REFRESH_TOKEN_TTL_SECONDS,
} from '../../infrastructure/services/jwt.service';

export interface IssuedTokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

/** Shared by verify-otp and refresh-token use-cases — issuing a fresh access+refresh pair is identical for both. */
@Injectable()
export class TokenIssuerService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly refreshTokenRepository: RefreshTokenRepository,
  ) {}

  async issue(userId: string): Promise<IssuedTokenPair> {
    const { accessToken, expiresIn } = this.jwtService.signAccessToken({
      sub: userId,
      scope: 'full',
      // No subscription table exists yet in the MVP schema — every user
      // starts on trial until Premium Infrastructure (Beta) lands.
      premiumStatus: 'trial',
    });

    const refreshToken = randomUUID();
    await this.refreshTokenRepository.create({
      userId,
      tokenHash: hashToken(refreshToken),
      expiresAt: new Date(Date.now() + REFRESH_TOKEN_TTL_SECONDS * 1000),
    });

    return { accessToken, refreshToken, expiresIn };
  }
}
