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

interface ErrorEnvelope {
  error: { code: string; message: string; traceId: string };
}

interface TransactionResource {
  id: string;
  accountId: string;
  amount: string;
  occurredAt: string;
}

interface ListEnvelope {
  data: TransactionResource[];
  meta: { nextCursor: string | null; hasMore: boolean; limit: number };
}

describe('Transactions CRUD (e2e)', () => {
  let app: INestApplication<App>;
  let userId: string;
  let accountId: string;
  let token: string;

  function authed(bearer: string) {
    return { Authorization: `Bearer ${bearer}` };
  }

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const users: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1) RETURNING id`,
      ['+77051110000'],
    );
    userId = users[0].id;

    const accounts: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO accounts (user_id, type, name, currency) VALUES ($1, 'cash', 'Наличные', 'KZT') RETURNING id`,
      [userId],
    );
    accountId = accounts[0].id;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    setupApp(app);
    await app.init();

    token = new JwtService({ secret: process.env.JWT_SECRET }).sign({
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

  it('POST /transactions with a non-existent accountId returns 404', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/transactions')
      .set(authed(token))
      .send({
        accountId: '00000000-0000-0000-0000-000000000000',
        amount: '1000.00',
        currency: 'KZT',
        type: 'expense',
      })
      .expect(404);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('NOT_FOUND');
  });

  it('POST /transactions with amount <= 0 returns 400 VALIDATION_ERROR', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/transactions')
      .set(authed(token))
      .send({
        accountId,
        amount: '0',
        currency: 'KZT',
        type: 'expense',
      })
      .expect(400);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('VALIDATION_ERROR');
  });

  it('cursor pagination neither loses nor duplicates rows when a new transaction is inserted between two page requests', async () => {
    const dates = [
      '2026-01-05',
      '2026-01-04',
      '2026-01-03',
      '2026-01-02',
      '2026-01-01',
    ];
    for (const occurredAt of dates) {
      await request(app.getHttpServer())
        .post('/api/v1/transactions')
        .set(authed(token))
        .send({
          accountId,
          amount: '100.00',
          currency: 'KZT',
          type: 'expense',
          occurredAt,
        })
        .expect(201);
    }

    const page1Response = await request(app.getHttpServer())
      .get('/api/v1/transactions')
      .query({ accountId, limit: 2 })
      .set(authed(token))
      .expect(200);
    const page1 = page1Response.body as ListEnvelope;

    expect(page1.data.map((t) => t.occurredAt.slice(0, 10))).toEqual([
      '2026-01-05',
      '2026-01-04',
    ]);
    expect(page1.meta.hasMore).toBe(true);
    expect(page1.meta.nextCursor).not.toBeNull();

    // Insert a transaction newer than everything already fetched, between
    // the two page requests.
    await request(app.getHttpServer())
      .post('/api/v1/transactions')
      .set(authed(token))
      .send({
        accountId,
        amount: '50.00',
        currency: 'KZT',
        type: 'expense',
        occurredAt: '2026-01-06',
      })
      .expect(201);

    const page2Response = await request(app.getHttpServer())
      .get('/api/v1/transactions')
      .query({ accountId, limit: 2, cursor: page1.meta.nextCursor! })
      .set(authed(token))
      .expect(200);
    const page2 = page2Response.body as ListEnvelope;

    expect(page2.data.map((t) => t.occurredAt.slice(0, 10))).toEqual([
      '2026-01-03',
      '2026-01-02',
    ]);

    const page1Ids = page1.data.map((t) => t.id);
    const page2Ids = page2.data.map((t) => t.id);
    expect(page1Ids.some((id) => page2Ids.includes(id))).toBe(false);
  });
});
