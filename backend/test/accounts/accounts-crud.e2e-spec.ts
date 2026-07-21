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

interface AccountResource {
  id: string;
  userId: string;
  type: string;
  name: string;
  currency: string;
  balanceCached: string;
  archived: boolean;
}

describe('Accounts CRUD (e2e)', () => {
  let app: INestApplication<App>;
  let user1Id: string;
  let user2Id: string;
  let user1Token: string;
  let user2Token: string;

  function authed(token: string) {
    return { Authorization: `Bearer ${token}` };
  }

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const users: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1), ($2) RETURNING id`,
      ['+77031110000', '+77031110001'],
    );
    user1Id = users[0].id;
    user2Id = users[1].id;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    setupApp(app);
    await app.init();

    const jwtService = new JwtService({ secret: process.env.JWT_SECRET });
    user1Token = jwtService.sign({
      sub: user1Id,
      scope: 'full',
      premiumStatus: 'trial',
    });
    user2Token = jwtService.sign({
      sub: user2Id,
      scope: 'full',
      premiumStatus: 'trial',
    });
  });

  afterAll(async () => {
    await app.close();
    await revertAllMigrations(AppDataSource);
    await AppDataSource.destroy();
  });

  it('POST /accounts creates an account owned by the caller, starting at zero balance', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/accounts')
      .set(authed(user1Token))
      .send({ type: 'cash', name: 'Наличные', currency: 'KZT' })
      .expect(201);

    const body = response.body as DataEnvelope<AccountResource>;
    expect(body.data.userId).toBe(user1Id);
    expect(body.data.balanceCached).toBe('0.00');
    expect(body.data.archived).toBe(false);
  });

  it('POST /accounts with an invalid currency returns 400 VALIDATION_ERROR', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/accounts')
      .set(authed(user1Token))
      .send({ type: 'cash', name: 'Наличные', currency: 'kzt' })
      .expect(400);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('VALIDATION_ERROR');
  });

  it("GET /accounts only returns the caller's own accounts", async () => {
    await request(app.getHttpServer())
      .post('/api/v1/accounts')
      .set(authed(user2Token))
      .send({ type: 'bank', name: 'Kaspi Gold', currency: 'KZT' })
      .expect(201);

    const response = await request(app.getHttpServer())
      .get('/api/v1/accounts')
      .set(authed(user1Token))
      .expect(200);

    const body = response.body as DataEnvelope<AccountResource[]>;
    expect(body.data.every((account) => account.userId === user1Id)).toBe(true);
  });

  it("PATCH on another user's account returns 404", async () => {
    const createResponse = await request(app.getHttpServer())
      .post('/api/v1/accounts')
      .set(authed(user2Token))
      .send({ type: 'cash', name: 'Только user2', currency: 'KZT' })
      .expect(201);
    const other = (createResponse.body as DataEnvelope<AccountResource>).data;

    const response = await request(app.getHttpServer())
      .patch(`/api/v1/accounts/${other.id}`)
      .set(authed(user1Token))
      .send({ name: 'Захват' })
      .expect(404);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('NOT_FOUND');
  });

  it('PATCH renames/archives an own account', async () => {
    const createResponse = await request(app.getHttpServer())
      .post('/api/v1/accounts')
      .set(authed(user1Token))
      .send({ type: 'card', name: 'Карта', currency: 'KZT' })
      .expect(201);
    const created = (createResponse.body as DataEnvelope<AccountResource>).data;

    const patchResponse = await request(app.getHttpServer())
      .patch(`/api/v1/accounts/${created.id}`)
      .set(authed(user1Token))
      .send({ name: 'Kaspi Gold', archived: true })
      .expect(200);

    const body = (patchResponse.body as DataEnvelope<AccountResource>).data;
    expect(body.name).toBe('Kaspi Gold');
    expect(body.archived).toBe(true);
  });

  it('DELETE soft-deletes: the account disappears from GET /accounts but the row survives', async () => {
    const createResponse = await request(app.getHttpServer())
      .post('/api/v1/accounts')
      .set(authed(user1Token))
      .send({ type: 'cash', name: 'Временный счёт', currency: 'KZT' })
      .expect(201);
    const created = (createResponse.body as DataEnvelope<AccountResource>).data;

    await request(app.getHttpServer())
      .delete(`/api/v1/accounts/${created.id}`)
      .set(authed(user1Token))
      .expect(204);

    const listResponse = await request(app.getHttpServer())
      .get('/api/v1/accounts')
      .set(authed(user1Token))
      .expect(200);
    const list = (listResponse.body as DataEnvelope<AccountResource[]>).data;
    expect(list.some((account) => account.id === created.id)).toBe(false);

    const rows: Array<{ id: string; deleted_at: Date | null }> =
      await AppDataSource.query(
        `SELECT id, deleted_at FROM accounts WHERE id = $1`,
        [created.id],
      );
    expect(rows).toHaveLength(1);
    expect(rows[0].deleted_at).not.toBeNull();
  });
});
