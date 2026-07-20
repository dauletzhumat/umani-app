import { Injectable } from '@nestjs/common';
import { JwtService as NestJwtService } from '@nestjs/jwt';
import { randomUUID } from 'crypto';
import { AccessTokenPayload } from '../../../../shared/types/access-token-payload';

export const ACCESS_TOKEN_TTL_SECONDS = 15 * 60;
export const REFRESH_TOKEN_TTL_SECONDS = 30 * 24 * 60 * 60;

@Injectable()
export class JwtService {
  constructor(private readonly nestJwtService: NestJwtService) {}

  signAccessToken(payload: AccessTokenPayload): {
    accessToken: string;
    expiresIn: number;
  } {
    const accessToken = this.nestJwtService.sign(
      { ...payload, jti: randomUUID() },
      { expiresIn: ACCESS_TOKEN_TTL_SECONDS },
    );

    return { accessToken, expiresIn: ACCESS_TOKEN_TTL_SECONDS };
  }
}
