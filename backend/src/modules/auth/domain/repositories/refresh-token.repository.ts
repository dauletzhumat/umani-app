import { RefreshToken } from '../entities/refresh-token.entity';

export interface CreateRefreshTokenData {
  userId: string;
  tokenHash: string;
  expiresAt: Date;
  deviceId?: string | null;
}

export abstract class RefreshTokenRepository {
  abstract create(data: CreateRefreshTokenData): Promise<void>;

  abstract findByHash(tokenHash: string): Promise<RefreshToken | null>;

  abstract revoke(id: string): Promise<void>;

  abstract revokeAllForUser(userId: string): Promise<void>;
}
