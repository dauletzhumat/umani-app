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
import { VisionService } from '../../src/modules/ocr/infrastructure/services/vision.service';
import { REDIS_CLIENT } from '../../src/shared/redis/redis.module';

interface DataEnvelope<T> {
  data: T;
}

interface ErrorEnvelope {
  error: { code: string; message: string; traceId: string };
}

interface DraftTransaction {
  merchant: string | null;
  amount: string | null;
  currency: string;
  suggestedCategoryId: string | null;
  lineItems: Array<{ name: string; price: string }>;
}

interface ScanResource {
  receiptScanId: string;
  status: string;
  draftTransaction?: DraftTransaction;
}

class FakeVisionService {
  isConfigured = true;
  nextText: string | null =
    'MAGNUM\nМолоко 2.5% 650.00\nИТОГО 12400.00\n22.07.2026';

  extractText(): Promise<string | null> {
    return Promise.resolve(this.nextText);
  }
}

class FakeOpenAiClientService {
  parseReceiptCallCount = 0;

  parseReceipt() {
    this.parseReceiptCallCount += 1;
    return Promise.resolve({
      merchant: 'Magnum',
      totalAmount: '12400.00',
      currency: 'KZT',
      date: '2026-07-22',
      lineItems: [{ name: 'Молоко 2.5%', price: '650.00' }],
    });
  }

  categorize() {
    return Promise.resolve({ categoryName: 'Продукты', confidence: 0.9 });
  }
}

describe('OCR receipt scanning (e2e)', () => {
  let app: INestApplication<App>;
  let userId: string;
  let categoryId: string;
  let token: string;
  const fakeVision = new FakeVisionService();
  const fakeOpenAiClient = new FakeOpenAiClientService();

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

    const categories: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO categories (user_id, name, icon) VALUES (NULL, 'Продукты', 'shopping_cart') RETURNING id`,
    );
    categoryId = categories[0].id;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(VisionService)
      .useValue(fakeVision)
      .overrideProvider(OpenAiClientService)
      .useValue(fakeOpenAiClient)
      .compile();

    app = moduleFixture.createNestApplication();
    setupApp(app);
    await app.init();

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

  it('a readable receipt returns a structured draft within 3s', async () => {
    const startedAt = Date.now();
    const response = await request(app.getHttpServer())
      .post('/api/v1/ocr/scans')
      .set(authed(token))
      .send({ storagePath: 'receipts/test-receipt.jpg' })
      .expect(201);
    const elapsedMs = Date.now() - startedAt;
    expect(elapsedMs).toBeLessThan(3000);

    const scan = (response.body as DataEnvelope<ScanResource>).data;
    expect(scan.status).toBe('processed');
    expect(scan.draftTransaction).toEqual<DraftTransaction>({
      merchant: 'Magnum',
      amount: '12400.00',
      currency: 'KZT',
      suggestedCategoryId: categoryId,
      lineItems: [{ name: 'Молоко 2.5%', price: '650.00' }],
    });

    const getResponse = await request(app.getHttpServer())
      .get(`/api/v1/ocr/scans/${scan.receiptScanId}`)
      .set(authed(token))
      .expect(200);
    const fetched = (getResponse.body as DataEnvelope<ScanResource>).data;
    expect(fetched.status).toBe('processed');
    expect(fetched.draftTransaction).toEqual(scan.draftTransaction);
  });

  it('an unreadable image returns 422 RECEIPT_UNREADABLE without calling OpenAI', async () => {
    fakeVision.nextText = null;
    const callsBefore = fakeOpenAiClient.parseReceiptCallCount;

    const response = await request(app.getHttpServer())
      .post('/api/v1/ocr/scans')
      .set(authed(token))
      .send({ storagePath: 'receipts/unreadable.jpg' })
      .expect(422);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('RECEIPT_UNREADABLE');
    expect(fakeOpenAiClient.parseReceiptCallCount).toBe(callsBefore);
  });
});
