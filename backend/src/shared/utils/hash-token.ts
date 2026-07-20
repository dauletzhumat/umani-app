import { createHash } from 'crypto';

/**
 * Deterministic hash for high-entropy opaque tokens (refresh tokens) that
 * need an exact-match DB lookup (uq_refresh_tokens_hash). Unlike bcrypt
 * (random salt per call, meant for low-entropy secrets checked against a
 * single known row), SHA-256 lets `WHERE token_hash = :hash` find the row.
 */
export function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}
