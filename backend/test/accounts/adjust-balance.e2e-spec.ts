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

interface TransactionResource {
  id: string;
  accountId: string;
  amount: string;
  type: string;
  note: string | null;
}

describe('POST /accounts/{id}/adjust-balance (e2e)', () => {
  let app: INestApplication<App>;
  let userId: string;
  let accountId: string;
  let token: string;

  function authed(bearer: string) {
    return { Authorization: `Bearer ${bearer}` };
  }

  async function getBalance(): Promise<string> {
    const rows: Array<{ balance_cached: string }> = await AppDataSource.query(
      `SELECT balance_cached FROM accounts WHERE id = $1`,
      [accountId],
    );
    return rows[0].balance_cached;
  }

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const users: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1) RETURNING id`,
      ['+77071110000'],
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

  it('creates an income correction with the default note and updates the balance', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/v1/accounts/${accountId}/adjust-balance`)
      .set(authed(token))
      .send({ amount: '1500.00' })
      .expect(201);

    const transaction = (response.body as DataEnvelope<TransactionResource>)
      .data;
    expect(transaction.accountId).toBe(accountId);
    expect(transaction.amount).toBe('1500.00');
    expect(transaction.type).toBe('income');
    expect(transaction.note).toBe('Сверка баланса');
    expect(await getBalance()).toBe('1500.00');
  });

  it('a negative amount creates an expense correction (absolute value stored)', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/v1/accounts/${accountId}/adjust-balance`)
      .set(authed(token))
      .send({ amount: '-500.00', note: 'Забыл про наличку' })
      .expect(201);

    const transaction = (response.body as DataEnvelope<TransactionResource>)
      .data;
    expect(transaction.amount).toBe('500.00');
    expect(transaction.type).toBe('expense');
    expect(transaction.note).toBe('Забыл про наличку');
    expect(await getBalance()).toBe('1000.00');
  });

  it('a zero amount returns 422 UNPROCESSABLE_BUSINESS_RULE', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/v1/accounts/${accountId}/adjust-balance`)
      .set(authed(token))
      .send({ amount: '0' })
      .expect(422);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('UNPROCESSABLE_BUSINESS_RULE');
  });

  it('a non-existent account returns 404', async () => {
    const response = await request(app.getHttpServer())
      .post(
        '/api/v1/accounts/00000000-0000-0000-0000-000000000000/adjust-balance',
      )
      .set(authed(token))
      .send({ amount: '100.00' })
      .expect(404);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('NOT_FOUND');
  });
});
