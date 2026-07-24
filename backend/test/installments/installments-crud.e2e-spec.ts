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

interface PaymentResource {
  dueDate: string;
  amount: string;
  status: string;
}

interface InstallmentResource {
  id: string;
  merchant: string;
  totalAmount: string;
  installmentsCount: number;
  payments: PaymentResource[];
}

interface InstallmentsOverviewResource {
  totalOutstanding: string;
  installments: Array<{
    id: string;
    merchant: string;
    nextPayment: { dueDate: string; amount: string } | null;
  }>;
}

describe('Installments CRUD (e2e)', () => {
  let app: INestApplication<App>;
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
      ['+77091110000'],
    );
    userId = users[0].id;

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

  it('POST /installments creates the record and generates a payment schedule summing to totalAmount', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/installments')
      .set(authed(token))
      .send({
        merchant: 'Technodom',
        totalAmount: '100000.00',
        installmentsCount: 3,
        startDate: '2026-07-01',
        provider: 'Kaspi Rassrochka',
      })
      .expect(201);

    const body = (response.body as DataEnvelope<InstallmentResource>).data;
    expect(body.payments).toHaveLength(3);
    const sum = body.payments.reduce((total, p) => total + Number(p.amount), 0);
    expect(sum.toFixed(2)).toBe('100000.00');
    expect(body.payments.every((p) => p.status === 'pending')).toBe(true);
    expect(body.payments[0].dueDate).toBe('2026-07-01');
  });

  it('GET /installments returns the summed debt load across all active installments', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/installments')
      .set(authed(token))
      .send({
        merchant: 'Sulpak',
        totalAmount: '60000.00',
        installmentsCount: 6,
        startDate: '2026-08-01',
      })
      .expect(201);

    const response = await request(app.getHttpServer())
      .get('/api/v1/installments')
      .set(authed(token))
      .expect(200);

    const body = (response.body as DataEnvelope<InstallmentsOverviewResource>)
      .data;
    // 100000 (Technodom, from the previous test) + 60000 (Sulpak) — all
    // payments are still pending, so totalOutstanding is the full sum.
    expect(body.totalOutstanding).toBe('160000.00');
    expect(body.installments).toHaveLength(2);

    const sulpak = body.installments.find((i) => i.merchant === 'Sulpak')!;
    expect(sulpak.nextPayment).toEqual({
      dueDate: '2026-08-01',
      amount: '10000.00',
    });
  });
});
