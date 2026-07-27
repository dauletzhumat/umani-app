import 'dotenv/config';
import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
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

interface DeleteAccountResponse {
  scheduledPurgeAt: string;
}

describe('Users DELETE /me (e2e)', () => {
  let app: INestApplication<App>;
  let userId: string;
  let accessToken: string;

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const rows: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1) RETURNING id`,
      ['+77061230001'],
    );
    userId = rows[0].id;

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

  it('DELETE /users/me returns 202 with a future scheduledPurgeAt, and the same token then gets 401 on GET /users/me', async () => {
    const beforeCall = Date.now();

    const deleteResponse = await request(app.getHttpServer())
      .delete('/api/v1/users/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(202);

    const deleteBody = deleteResponse.body as DataEnvelope<DeleteAccountResponse>;
    const scheduledPurgeAt = new Date(deleteBody.data.scheduledPurgeAt);
    expect(scheduledPurgeAt.getTime()).toBeGreaterThan(beforeCall);

    const getResponse = await request(app.getHttpServer())
      .get('/api/v1/users/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(401);
    const getBody = getResponse.body as ErrorEnvelope;
    expect(getBody.error.code).toBe('UNAUTHORIZED');
  });

  it('a second DELETE /users/me call is idempotent — it returns the original scheduledPurgeAt unchanged', async () => {
    const first = await request(app.getHttpServer())
      .delete('/api/v1/users/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(202);
    const firstBody = first.body as DataEnvelope<DeleteAccountResponse>;

    const second = await request(app.getHttpServer())
      .delete('/api/v1/users/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(202);
    const secondBody = second.body as DataEnvelope<DeleteAccountResponse>;

    expect(secondBody.data.scheduledPurgeAt).toBe(
      firstBody.data.scheduledPurgeAt,
    );
  });
});
