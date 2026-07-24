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

interface BudgetResource {
  id: string;
}

interface NotificationResource {
  id: string;
  type: string;
  payload: { budgetId?: string; threshold?: number };
}

describe('Budget threshold notifications (e2e)', () => {
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
      ['+77071110000'],
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
  });

  afterAll(async () => {
    await app.close();
    await revertAllMigrations(AppDataSource);
    await AppDataSource.destroy();
  });

  it('several transactions in a row after crossing 80% do not create duplicate notifications within the same period', async () => {
    const budgetResponse = await request(app.getHttpServer())
      .post('/api/v1/budgets')
      .set(authed(token))
      .send({
        categoryId,
        amountLimit: '10000.00',
        period: 'monthly',
        startDate: '2026-07-01',
      })
      .expect(201);
    const budgetId = (budgetResponse.body as DataEnvelope<BudgetResource>).data
      .id;

    async function budgetThresholdNotifications() {
      const response = await request(app.getHttpServer())
        .get('/api/v1/notifications')
        .set(authed(token))
        .expect(200);
      const notifications = (
        response.body as DataEnvelope<NotificationResource[]>
      ).data;
      return notifications.filter(
        (n) => n.type === 'budget_threshold' && n.payload.budgetId === budgetId,
      );
    }

    async function postExpense(amount: string, occurredAt: string) {
      await request(app.getHttpServer())
        .post('/api/v1/transactions')
        .set(authed(token))
        .send({
          accountId,
          categoryId,
          amount,
          currency: 'KZT',
          type: 'expense',
          occurredAt,
        })
        .expect(201);
    }

    // Crosses 80% (8500/10000) on the first transaction.
    await postExpense('8500.00', '2026-07-05');
    let notifications = await budgetThresholdNotifications();
    expect(
      notifications.filter((n) => n.payload.threshold === 80),
    ).toHaveLength(1);
    expect(notifications.some((n) => n.payload.threshold === 100)).toBe(false);

    // Two more transactions, still under 100% — must not duplicate the 80% notification.
    await postExpense('100.00', '2026-07-06');
    await postExpense('100.00', '2026-07-07');

    notifications = await budgetThresholdNotifications();
    expect(
      notifications.filter((n) => n.payload.threshold === 80),
    ).toHaveLength(1);
    expect(notifications.some((n) => n.payload.threshold === 100)).toBe(false);
  });
});
