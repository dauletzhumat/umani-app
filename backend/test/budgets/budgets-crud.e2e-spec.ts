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

interface BudgetResource {
  id: string;
  categoryId: string;
  categoryName: string;
  amountLimit: string;
  period: string;
  startDate: string;
  spentAmount: string;
  remainingAmount: string;
  progressPercent: number;
}

describe('Budgets CRUD (e2e)', () => {
  let app: INestApplication<App>;
  let userId: string;
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
      ['+77061110000'],
    );
    userId = users[0].id;

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
  });

  afterAll(async () => {
    await app.close();
    await revertAllMigrations(AppDataSource);
    await AppDataSource.destroy();
  });

  it('POST /budgets creates a budget with zeroed progress', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/budgets')
      .set(authed(token))
      .send({
        categoryId,
        amountLimit: '80000.00',
        period: 'monthly',
        startDate: '2026-07-01',
      })
      .expect(201);

    const body = (response.body as DataEnvelope<BudgetResource>).data;
    expect(body.categoryName).toBe('Еда');
    expect(body.spentAmount).toBe('0.00');
    expect(body.remainingAmount).toBe('80000.00');
    expect(body.progressPercent).toBe(0);
  });

  it('a repeat budget for the same category/period/startDate returns 409 CONFLICT (uq_budgets_user_category_period)', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/budgets')
      .set(authed(token))
      .send({
        categoryId,
        amountLimit: '50000.00',
        period: 'monthly',
        startDate: '2026-07-01',
      })
      .expect(409);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('CONFLICT');
  });

  it('a different startDate for the same category/period does not conflict', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/budgets')
      .set(authed(token))
      .send({
        categoryId,
        amountLimit: '80000.00',
        period: 'monthly',
        startDate: '2026-08-01',
      })
      .expect(201);
  });

  it('a soft-deleted budget frees its category/period/startDate for a new one (partial unique index)', async () => {
    const createResponse = await request(app.getHttpServer())
      .post('/api/v1/budgets')
      .set(authed(token))
      .send({
        categoryId,
        amountLimit: '30000.00',
        period: 'weekly',
        startDate: '2026-09-01',
      })
      .expect(201);
    const created = (createResponse.body as DataEnvelope<BudgetResource>).data;

    await request(app.getHttpServer())
      .delete(`/api/v1/budgets/${created.id}`)
      .set(authed(token))
      .expect(204);

    await request(app.getHttpServer())
      .post('/api/v1/budgets')
      .set(authed(token))
      .send({
        categoryId,
        amountLimit: '35000.00',
        period: 'weekly',
        startDate: '2026-09-01',
      })
      .expect(201);
  });
});
