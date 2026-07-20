import 'dotenv/config';
import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { createHash, randomUUID } from 'crypto';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../../src/app.module';
import { setupApp } from '../../src/setup-app';
import { AppDataSource } from '../../src/database/data-source';
import { revertAllMigrations } from '../database/migration-test-utils';

function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

interface DataEnvelope<T> {
  data: T;
}

interface ErrorEnvelope {
  error: { code: string; message: string; traceId: string };
}

interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

describe('Auth refresh/logout (e2e)', () => {
  let app: INestApplication<App>;
  let userId: string;
  let accessToken: string;

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const userRows: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1) RETURNING id`,
      ['+77041110000'],
    );
    userId = userRows[0].id;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    setupApp(app);
    await app.init();

    accessToken = new JwtService({ secret: process.env.JWT_SECRET }).sign({
      sub: userId,
      scope: 'full',
      premiumStatus: 'trial',
    });
  });

  afterAll(async () => {
    await app.close();
    await revertAllMigrations(AppDataSource);
    await AppDataSource.destroy();
  });

  async function seedRefreshToken(
    overrides: { issuedAt?: Date; expiresAt?: Date } = {},
  ): Promise<string> {
    const raw = randomUUID();
    await AppDataSource.query(
      `INSERT INTO refresh_tokens (user_id, token_hash, issued_at, expires_at)
       VALUES ($1, $2, $3, $4)`,
      [
        userId,
        hashToken(raw),
        overrides.issuedAt ?? new Date(),
        overrides.expiresAt ?? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      ],
    );
    return raw;
  }

  async function revokedAtFor(rawToken: string): Promise<Date | null> {
    const rows: Array<{ revoked_at: Date | null }> = await AppDataSource.query(
      `SELECT revoked_at FROM refresh_tokens WHERE token_hash = $1`,
      [hashToken(rawToken)],
    );
    return rows[0].revoked_at;
  }

  it('rotates: issues a new pair and revokes the old refresh token', async () => {
    const oldToken = await seedRefreshToken();

    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: oldToken })
      .expect(200);

    const body = response.body as DataEnvelope<TokenPair>;
    expect(body.data.accessToken).toEqual(expect.any(String));
    expect(body.data.refreshToken).not.toBe(oldToken);
    expect(await revokedAtFor(oldToken)).not.toBeNull();
  });

  it('rejects reuse of an already-revoked token with 401 TOKEN_REVOKED and revokes all sessions', async () => {
    const tokenA = await seedRefreshToken();
    const tokenB = await seedRefreshToken();

    await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: tokenA })
      .expect(200);

    const replay = await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: tokenA })
      .expect(401);
    const replayBody = replay.body as ErrorEnvelope;
    expect(replayBody.error.code).toBe('TOKEN_REVOKED');

    expect(await revokedAtFor(tokenB)).not.toBeNull();
  });

  it('returns 401 TOKEN_EXPIRED for an expired token', async () => {
    const expired = await seedRefreshToken({
      issuedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
      expiresAt: new Date(Date.now() - 1000),
    });

    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: expired })
      .expect(401);
    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('TOKEN_EXPIRED');
  });

  it('returns 401 UNAUTHORIZED for an unknown token', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: randomUUID() })
      .expect(401);
    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('UNAUTHORIZED');
  });

  it('rejects protected routes without a Bearer token', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/logout-all')
      .expect(401);
    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('UNAUTHORIZED');
  });

  it('logout revokes only the specified session', async () => {
    const tokenA = await seedRefreshToken();
    const tokenB = await seedRefreshToken();

    await request(app.getHttpServer())
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ refreshToken: tokenA })
      .expect(204);

    expect(await revokedAtFor(tokenA)).not.toBeNull();
    expect(await revokedAtFor(tokenB)).toBeNull();
  });

  it('logout-all revokes every active session for the user', async () => {
    const tokenA = await seedRefreshToken();
    const tokenB = await seedRefreshToken();

    await request(app.getHttpServer())
      .post('/api/v1/auth/logout-all')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(204);

    expect(await revokedAtFor(tokenA)).not.toBeNull();
    expect(await revokedAtFor(tokenB)).not.toBeNull();
  });
});
