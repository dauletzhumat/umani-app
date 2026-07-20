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

interface VerifyOtpData {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: { id: string; isNewUser: boolean };
}

interface DecodedAccessToken {
  sub: string;
  exp: number;
}

function decodeAccessToken(token: string): DecodedAccessToken {
  const decoded: unknown = new JwtService().decode(token);
  const record = decoded as Record<string, unknown> | null;

  if (
    typeof record !== 'object' ||
    record === null ||
    typeof record.sub !== 'string' ||
    typeof record.exp !== 'number'
  ) {
    throw new Error('Failed to decode access token');
  }

  return { sub: record.sub, exp: record.exp };
}

describe('Auth otp/verify (e2e)', () => {
  let app: INestApplication<App>;

  const CODE = '123456';
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

  async function seedOtp(identifier: string, attempts = 0): Promise<void> {
    await AppDataSource.query(
      `INSERT INTO otp_codes (identifier, code_hash, attempts, expires_at)
       VALUES ($1, $2, $3, now() + interval '5 minutes')`,
      [identifier, codeHash, attempts],
    );
  }

  it('creates a new user and returns a valid JWT for a correct code', async () => {
    const identifier = '+77011110001';
    await seedOtp(identifier);

    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/otp/verify')
      .send({ identifier, code: CODE })
      .expect(200);

    const body = response.body as DataEnvelope<VerifyOtpData>;
    expect(body.data.user.isNewUser).toBe(true);
    expect(body.data.expiresIn).toBe(900);
    expect(body.data.refreshToken).toEqual(expect.any(String));

    const decoded = decodeAccessToken(body.data.accessToken);
    expect(decoded.sub).toBe(body.data.user.id);
    expect(decoded.exp).toBeGreaterThan(Date.now() / 1000);
  });

  it('returns an existing user with isNewUser: false on a second verify', async () => {
    const identifier = '+77011110002';
    await seedOtp(identifier);
    const first = await request(app.getHttpServer())
      .post('/api/v1/auth/otp/verify')
      .send({ identifier, code: CODE })
      .expect(200);
    const firstBody = first.body as DataEnvelope<VerifyOtpData>;

    await seedOtp(identifier);
    const second = await request(app.getHttpServer())
      .post('/api/v1/auth/otp/verify')
      .send({ identifier, code: CODE })
      .expect(200);
    const secondBody = second.body as DataEnvelope<VerifyOtpData>;

    expect(secondBody.data.user.isNewUser).toBe(false);
    expect(secondBody.data.user.id).toBe(firstBody.data.user.id);
  });

  it('returns 400 OTP_INVALID for a wrong code', async () => {
    const identifier = '+77011110003';
    await seedOtp(identifier);

    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/otp/verify')
      .send({ identifier, code: '000000' })
      .expect(400);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('OTP_INVALID');
  });

  it('returns 429 TOO_MANY_ATTEMPTS on the 6th consecutive wrong attempt, not 400', async () => {
    const identifier = '+77011110004';
    await seedOtp(identifier);

    for (let attempt = 1; attempt <= 5; attempt++) {
      const response = await request(app.getHttpServer())
        .post('/api/v1/auth/otp/verify')
        .send({ identifier, code: '000000' })
        .expect(400);
      const body = response.body as ErrorEnvelope;
      expect(body.error.code).toBe('OTP_INVALID');
    }

    const sixth = await request(app.getHttpServer())
      .post('/api/v1/auth/otp/verify')
      .send({ identifier, code: '000000' })
      .expect(429);
    const sixthBody = sixth.body as ErrorEnvelope;
    expect(sixthBody.error.code).toBe('TOO_MANY_ATTEMPTS');

    const rows: Array<{ attempts: number }> = await AppDataSource.query(
      `SELECT attempts FROM otp_codes WHERE identifier = $1`,
      [identifier],
    );
    expect(rows[0].attempts).toBe(5);
  });
});
