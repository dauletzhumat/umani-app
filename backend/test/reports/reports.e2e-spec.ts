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

interface CategoryBreakdownResource {
  categoryId: string | null;
  categoryName: string;
  amount: string;
  percentage: number;
}

interface ByCategoryResource {
  totalExpense: string;
  categories: CategoryBreakdownResource[];
}

interface SummaryResource {
  totalIncome: string;
  totalExpense: string;
}

describe('Reports (e2e)', () => {
  let app: INestApplication<App>;
  let userId: string;
  let accountId: string;
  let categoryId: string;
  let token: string;

  function authed(bearer: string) {
    return { Authorization: `Bearer ${bearer}` };
  }

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const users: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1) RETURNING id`,
      ['+77111110000'],
    );
    userId = users[0].id;

    const accounts: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO accounts (user_id, type, name, currency) VALUES ($1, 'cash', 'Наличные', 'KZT') RETURNING id`,
      [userId],
    );
    accountId = accounts[0].id;

    const categories: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO categories (user_id, name, icon) VALUES ($1, 'Еда', 'restaurant') RETURNING id`,
      [userId],
    );
    categoryId = categories[0].id;

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

    // All default to today via CreateTransactionDto -> within the
    // default period=month window.
    await request(app.getHttpServer())
      .post('/api/v1/transactions')
      .set(authed(token))
      .send({
        accountId,
        categoryId,
        amount: '5000.00',
        currency: 'KZT',
        type: 'expense',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/api/v1/transactions')
      .set(authed(token))
      .send({
        accountId,
        amount: '3000.00',
        currency: 'KZT',
        type: 'expense',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/api/v1/transactions')
      .set(authed(token))
      .send({
        accountId,
        amount: '100000.00',
        currency: 'KZT',
        type: 'income',
      })
      .expect(201);
  });

  afterAll(async () => {
    await app.close();
    await revertAllMigrations(AppDataSource);
    await AppDataSource.destroy();
  });

  it('groups uncategorized transactions into "Без категории" instead of dropping them from the total', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/reports/by-category')
      .set(authed(token))
      .expect(200);

    const body = (response.body as DataEnvelope<ByCategoryResource>).data;
    // 5000 (Еда) + 3000 (uncategorized) — both counted, none dropped.
    expect(body.totalExpense).toBe('8000.00');

    const food = body.categories.find((c) => c.categoryId === categoryId);
    expect(food?.amount).toBe('5000.00');

    const uncategorized = body.categories.find((c) => c.categoryId === null);
    expect(uncategorized?.categoryName).toBe('Без категории');
    expect(uncategorized?.amount).toBe('3000.00');
  });

  it('GET /reports/summary totals income and expense for the period', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/reports/summary')
      .set(authed(token))
      .expect(200);

    const body = (response.body as DataEnvelope<SummaryResource>).data;
    expect(body.totalIncome).toBe('100000.00');
    expect(body.totalExpense).toBe('8000.00');
  });
});
