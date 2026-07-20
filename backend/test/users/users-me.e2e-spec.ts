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

interface UserProfile {
  id: string;
  phone: string | null;
  email: string | null;
  name: string | null;
  locale: string;
  defaultCurrency: string;
}

describe('Users /me (e2e)', () => {
  let app: INestApplication<App>;
  let userId: string;
  let accessToken: string;

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const rows: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1) RETURNING id`,
      ['+77061230000'],
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

  it('GET /users/me without a token returns 401', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/users/me')
      .expect(401);
    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('UNAUTHORIZED');
  });

  it('GET /users/me with a token returns the correct fields', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/users/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    const body = response.body as DataEnvelope<UserProfile>;
    expect(body.data.id).toBe(userId);
    expect(body.data.phone).toBe('+77061230000');
    expect(body.data.locale).toBe('ru');
    expect(body.data.defaultCurrency).toBe('KZT');
  });

  it('PATCH /users/me with an invalid locale returns 400 VALIDATION_ERROR', async () => {
    const response = await request(app.getHttpServer())
      .patch('/api/v1/users/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ locale: 'fr' })
      .expect(400);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('VALIDATION_ERROR');
  });

  it('PATCH /users/me updates and persists name/locale/defaultCurrency', async () => {
    const patchResponse = await request(app.getHttpServer())
      .patch('/api/v1/users/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ name: 'Dana', locale: 'kk', defaultCurrency: 'USD' })
      .expect(200);

    const patchBody = patchResponse.body as DataEnvelope<UserProfile>;
    expect(patchBody.data.name).toBe('Dana');
    expect(patchBody.data.locale).toBe('kk');
    expect(patchBody.data.defaultCurrency).toBe('USD');

    const getResponse = await request(app.getHttpServer())
      .get('/api/v1/users/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    const getBody = getResponse.body as DataEnvelope<UserProfile>;
    expect(getBody.data.name).toBe('Dana');
    expect(getBody.data.locale).toBe('kk');
    expect(getBody.data.defaultCurrency).toBe('USD');
  });
});
