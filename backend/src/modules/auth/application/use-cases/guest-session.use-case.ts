import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { JwtService } from '../../infrastructure/services/jwt.service';

export interface GuestSessionResult {
  accessToken: string;
  expiresIn: number;
}

/**
 * No refresh token, no `users` row — a guest session is purely a signed
 * claim, never persisted server-side (docs/08_API.md §2: "сессия только
 * на устройстве, не переживает переустановку"). Also can't persist one:
 * chk_users_has_identifier requires a phone or email, which a guest has
 * neither of yet.
 */
@Injectable()
export class GuestSessionUseCase {
  constructor(private readonly jwtService: JwtService) {}

  execute(): GuestSessionResult {
    return this.jwtService.signAccessToken({
      sub: randomUUID(),
      scope: 'guest',
      premiumStatus: 'trial',
    });
  }
}
