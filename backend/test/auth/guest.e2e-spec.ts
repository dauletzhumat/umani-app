import 'dotenv/config';
import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../../src/app.module';
import { setupApp } from '../../src/setup-app';
import { AppDataSource } from '../../src/database/data-source';
import { revertAllMigrations } from '../database/migration-test-utils';

interface DataEnvelope<T> {
  data: T;
}

interface ErrorEnvelope {
  error: { code: string; message: string; traceId: string };
}

interface GuestSessionData {
  accessToken: string;
  expiresIn: number;
}

interface UpgradeData {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: { id: string; phone: string | null; isNewUser: boolean };
}

interface DecodedToken {
  sub: string;
  scope: string;
}

function decodeToken(token: string): DecodedToken {
  const decoded: unknown = new JwtService().decode(token);
  const record = decoded as Record<string, unknown> | null;

  if (
    typeof record !== 'object' ||
    record === null ||
    typeof record.sub !== 'string' ||
    typeof record.scope !== 'string'
  ) {
    throw new Error('Failed to decode token');
  }

  return { sub: record.sub, scope: record.scope };
}

const CODE = '654321';

describe('Auth guest (e2e)', () => {
  let app: INestApplication<App>;
  let codeHash: string;

  beforeAll(async () => {
    codeHash = await bcrypt.hash(CODE, 10);

    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    setupApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
    await revertAllMigrations(AppDataSource);
    await AppDataSource.destroy();
  });

  async function seedOtp(identifier: string): Promise<void> {
    await AppDataSource.query(
      `INSERT INTO otp_codes (identifier, code_hash, expires_at)
       VALUES ($1, $2, now() + interval '5 minutes')`,
      [identifier, codeHash],
    );
  }

  async function issueGuestSession(): Promise<DataEnvelope<GuestSessionData>> {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/guest')
      .expect(200);
    return response.body as DataEnvelope<GuestSessionData>;
  }

  it('issues a guest access token with scope: guest and no refresh token', async () => {
    const body = await issueGuestSession();

    expect(body.data.accessToken).toEqual(expect.any(String));
    expect('refreshToken' in body.data).toBe(false);
    expect(decodeToken(body.data.accessToken).scope).toBe('guest');
  });

  it('cannot use a guest session to refresh — no refresh token was ever issued for it', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: 'anything-a-guest-session-might-try' })
      .expect(401);
    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('UNAUTHORIZED');
  });

  it('upgrades a guest into a full user under the same user_id', async () => {
    const guest = await issueGuestSession();
    const guestUserId = decodeToken(guest.data.accessToken).sub;

    const identifier = '+77051230001';
    await seedOtp(identifier);

    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/guest/upgrade')
      .set('Authorization', `Bearer ${guest.data.accessToken}`)
      .send({ identifier, code: CODE })
      .expect(200);

    const body = response.body as DataEnvelope<UpgradeData>;
    expect(body.data.user.id).toBe(guestUserId);
    expect(body.data.user.phone).toBe(identifier);
    expect(body.data.user.isNewUser).toBe(true);
    expect(body.data.refreshToken).toEqual(expect.any(String));
  });

  it('rejects upgrade attempts from a non-guest access token with 403 FORBIDDEN_ROLE', async () => {
    const fullToken = new JwtService({ secret: process.env.JWT_SECRET }).sign({
      sub: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      scope: 'full',
      premiumStatus: 'trial',
    });

    const identifier = '+77051230002';
    await seedOtp(identifier);

    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/guest/upgrade')
      .set('Authorization', `Bearer ${fullToken}`)
      .send({ identifier, code: CODE })
      .expect(403);
    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('FORBIDDEN_ROLE');
  });

  it('rejects upgrading to an identifier already used by another user with 409 USER_ALREADY_EXISTS', async () => {
    const takenIdentifier = '+77051230003';
    await AppDataSource.query(`INSERT INTO users (phone) VALUES ($1)`, [
      takenIdentifier,
    ]);
    await seedOtp(takenIdentifier);

    const guest = await issueGuestSession();

    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/guest/upgrade')
      .set('Authorization', `Bearer ${guest.data.accessToken}`)
      .send({ identifier: takenIdentifier, code: CODE })
      .expect(409);
    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('USER_ALREADY_EXISTS');
  });

  it('rejects a second upgrade of an already-upgraded guest session with 409 CONFLICT', async () => {
    const guest = await issueGuestSession();

    const firstIdentifier = '+77051230004';
    await seedOtp(firstIdentifier);
    await request(app.getHttpServer())
      .post('/api/v1/auth/guest/upgrade')
      .set('Authorization', `Bearer ${guest.data.accessToken}`)
      .send({ identifier: firstIdentifier, code: CODE })
      .expect(200);

    const secondIdentifier = '+77051230005';
    await seedOtp(secondIdentifier);
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/guest/upgrade')
      .set('Authorization', `Bearer ${guest.data.accessToken}`)
      .send({ identifier: secondIdentifier, code: CODE })
      .expect(409);
    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('CONFLICT');
  });
});
