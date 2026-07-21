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

interface TransactionResource {
  id: string;
}

describe('Account balance recalculation (e2e)', () => {
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
      ['+77061110000'],
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

  it('starts at 0.00', async () => {
    expect(await getBalance()).toBe('0.00');
  });

  it('an income transaction increases the balance', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/transactions')
      .set(authed(token))
      .send({
        accountId,
        amount: '5000.00',
        currency: 'KZT',
        type: 'income',
      })
      .expect(201);

    expect(await getBalance()).toBe('5000.00');
  });

  it('an expense transaction decreases the balance', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/transactions')
      .set(authed(token))
      .send({
        accountId,
        amount: '1200.00',
        currency: 'KZT',
        type: 'expense',
      })
      .expect(201);

    expect(await getBalance()).toBe('3800.00');
  });

  it('editing a transaction amount recalculates the balance', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/transactions')
      .set(authed(token))
      .send({
        accountId,
        amount: '100.00',
        currency: 'KZT',
        type: 'expense',
      })
      .expect(201);
    const created = (response.body as DataEnvelope<TransactionResource>).data;
    expect(await getBalance()).toBe('3700.00');

    await request(app.getHttpServer())
      .patch(`/api/v1/transactions/${created.id}`)
      .set(authed(token))
      .send({ amount: '400.00' })
      .expect(200);

    expect(await getBalance()).toBe('3400.00');

    await request(app.getHttpServer())
      .delete(`/api/v1/transactions/${created.id}`)
      .set(authed(token))
      .expect(204);

    expect(await getBalance()).toBe('3800.00');
  });
});
