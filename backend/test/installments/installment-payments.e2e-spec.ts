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
import { InstallmentReminderJob } from '../../src/modules/installments/infrastructure/jobs/installment-reminder.job';

interface DataEnvelope<T> {
  data: T;
}

interface PaymentResource {
  id: string;
  status: string;
}

interface InstallmentResource {
  id: string;
  payments: PaymentResource[];
}

interface NotificationRow {
  id: string;
  type: string;
  payload: { paymentId?: string };
}

function inDays(days: number): string {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

describe('Installment payments (e2e)', () => {
  let app: INestApplication<App>;
  let moduleFixture: TestingModule;
  let userId: string;
  let token: string;

  function authed(bearer: string) {
    return { Authorization: `Bearer ${bearer}` };
  }

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const users: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1) RETURNING id`,
      ['+77101110000'],
    );
    userId = users[0].id;

    moduleFixture = await Test.createTestingModule({
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

  it('marking one payment paid does not change the status of the other payments in the schedule', async () => {
    const createResponse = await request(app.getHttpServer())
      .post('/api/v1/installments')
      .set(authed(token))
      .send({
        merchant: 'Technodom',
        totalAmount: '90000.00',
        installmentsCount: 3,
        startDate: '2026-07-01',
      })
      .expect(201);
    const installment = (
      createResponse.body as DataEnvelope<InstallmentResource>
    ).data;
    const [first, second, third] = installment.payments;

    await request(app.getHttpServer())
      .patch(`/api/v1/installments/${installment.id}/payments/${first.id}`)
      .set(authed(token))
      .expect(200);

    const rows: Array<{ id: string; status: string }> =
      await AppDataSource.query(
        `SELECT id, status FROM installment_payments WHERE installment_id = $1 ORDER BY due_date ASC`,
        [installment.id],
      );
    expect(rows.find((r) => r.id === first.id)!.status).toBe('paid');
    expect(rows.find((r) => r.id === second.id)!.status).toBe('pending');
    expect(rows.find((r) => r.id === third.id)!.status).toBe('pending');
  });

  it('the reminder cron notifies only for pending payments due within 1-3 days', async () => {
    const installments: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO installments (user_id, merchant, total_amount, installments_count, start_date)
       VALUES ($1, 'Sulpak', 30000.00, 3, '2026-01-01') RETURNING id`,
      [userId],
    );
    const installmentId = installments[0].id;

    const inWindowPending: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO installment_payments (installment_id, due_date, amount, status) VALUES ($1, $2, 10000.00, 'pending') RETURNING id`,
      [installmentId, inDays(2)],
    );
    await AppDataSource.query(
      `INSERT INTO installment_payments (installment_id, due_date, amount, status) VALUES ($1, $2, 10000.00, 'pending')`,
      [installmentId, inDays(5)],
    );
    await AppDataSource.query(
      `INSERT INTO installment_payments (installment_id, due_date, amount, status, paid_at) VALUES ($1, $2, 10000.00, 'paid', now())`,
      [installmentId, inDays(2)],
    );

    const job = moduleFixture.get(InstallmentReminderJob);
    await job.run();

    const notifications: NotificationRow[] = await AppDataSource.query(
      `SELECT id, type, payload FROM notifications WHERE user_id = $1 AND type = 'installment_payment_reminder'`,
      [userId],
    );
    expect(notifications).toHaveLength(1);
    expect(notifications[0].payload.paymentId).toBe(inWindowPending[0].id);

    // Running it again the same "day" must not duplicate the reminder.
    await job.run();
    const notificationsAfterRerun: NotificationRow[] =
      await AppDataSource.query(
        `SELECT id FROM notifications WHERE user_id = $1 AND type = 'installment_payment_reminder'`,
        [userId],
      );
    expect(notificationsAfterRerun).toHaveLength(1);
  });
});
