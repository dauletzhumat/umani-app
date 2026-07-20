import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
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

describe('Auth register/login (e2e)', () => {
  let app: INestApplication<App>;

  const existingPhone = '+77011234567';
  const newPhone = '+77021234567';
  const unknownPhone = '+77031234567';

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();
    await AppDataSource.query(`INSERT INTO users (phone) VALUES ($1)`, [
      existingPhone,
    ]);

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

  it('POST /auth/register with a new phone returns 202 and otpSentTo', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({ identifier: newPhone })
      .expect(202);

    const body = response.body as DataEnvelope<{
      otpSentTo: string;
      expiresInSeconds: number;
    }>;
    expect(body.data.otpSentTo).toEqual(expect.any(String));
    expect(body.data.expiresInSeconds).toBe(300);
  });

  it('POST /auth/register with an already-registered phone returns 409 USER_ALREADY_EXISTS', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({ identifier: existingPhone })
      .expect(409);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('USER_ALREADY_EXISTS');
    expect(body.error.traceId).toEqual(expect.any(String));
  });

  it('POST /auth/login with a registered phone returns 202 and otpSentTo', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ identifier: existingPhone })
      .expect(202);

    const body = response.body as DataEnvelope<{ otpSentTo: string }>;
    expect(body.data.otpSentTo).toEqual(expect.any(String));
  });

  it('POST /auth/login with an unregistered phone returns 404 NOT_FOUND', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ identifier: unknownPhone })
      .expect(404);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('NOT_FOUND');
  });

  it('POST /auth/register with a malformed identifier returns 400 VALIDATION_ERROR', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({ identifier: 'not-a-phone-or-email' })
      .expect(400);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('VALIDATION_ERROR');
  });
});
