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
import { OpenAiClientService } from '../../src/modules/ai/infrastructure/services/openai-client.service';
import { REDIS_CLIENT } from '../../src/shared/redis/redis.module';

interface DataEnvelope<T> {
  data: T;
}

interface TransactionResource {
  id: string;
  categoryId: string | null;
}

class FakeOpenAiClientService {
  callCount = 0;

  categorize() {
    this.callCount += 1;
    return Promise.resolve({ categoryName: 'Продукты', confidence: 0.9 });
  }
}

describe('AI categorization cache (e2e)', () => {
  let app: INestApplication<App>;
  let userId: string;
  let accountId: string;
  let categoryId: string;
  let token: string;
  const fakeOpenAiClient = new FakeOpenAiClientService();

  function authed(bearer: string) {
    return { Authorization: `Bearer ${bearer}` };
  }

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const users: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1) RETURNING id`,
      ['+77081110000'],
    );
    userId = users[0].id;

    const accounts: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO accounts (user_id, type, name, currency) VALUES ($1, 'cash', 'Наличные', 'KZT') RETURNING id`,
      [userId],
    );
    accountId = accounts[0].id;

    const categories: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO categories (user_id, name, icon) VALUES (NULL, 'Продукты', 'shopping_cart') RETURNING id`,
    );
    categoryId = categories[0].id;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(OpenAiClientService)
      .useValue(fakeOpenAiClient)
      .compile();

    app = moduleFixture.createNestApplication();
    setupApp(app);
    await app.init();

    // A shared Redis instance can carry a cached completion over from a
    // previous run for the same merchant+amount — flush it so this test
    // exercises the fake, not a stale entry from earlier.
    await app.get<import('ioredis').default>(REDIS_CLIENT).flushdb();

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

  it(
    'a second transaction with the same merchant+amount reuses the cached ' +
      'categorization instead of calling OpenAI again',
    async () => {
      const first = await request(app.getHttpServer())
        .post('/api/v1/transactions')
        .set(authed(token))
        .send({
          accountId,
          amount: '2500.00',
          currency: 'KZT',
          type: 'expense',
          note: 'Magnum',
        })
        .expect(201);
      const firstTransaction = (first.body as DataEnvelope<TransactionResource>)
        .data;
      expect(firstTransaction.categoryId).toBe(categoryId);
      expect(fakeOpenAiClient.callCount).toBe(1);

      const second = await request(app.getHttpServer())
        .post('/api/v1/transactions')
        .set(authed(token))
        .send({
          accountId,
          amount: '2500.00',
          currency: 'KZT',
          type: 'expense',
          note: 'Magnum',
        })
        .expect(201);
      const secondTransaction = (
        second.body as DataEnvelope<TransactionResource>
      ).data;
      expect(secondTransaction.categoryId).toBe(categoryId);
      expect(fakeOpenAiClient.callCount).toBe(1);
    },
  );
});
