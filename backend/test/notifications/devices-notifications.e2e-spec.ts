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

interface DeviceResource {
  id: string;
  userId: string;
  fcmToken: string;
  platform: string;
}

interface NotificationResource {
  id: string;
  userId: string;
  type: string;
  readAt: string | null;
}

describe('Devices/Notifications (e2e)', () => {
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
      ['+77032220000'],
    );
    userId = users[0].id;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    setupApp(app);
    await app.init();

    const jwtService = new JwtService({ secret: process.env.JWT_SECRET });
    token = jwtService.sign({
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

  it('POST /devices twice with the same fcmToken upserts instead of duplicating (uq_devices_user_token)', async () => {
    const first = await request(app.getHttpServer())
      .post('/api/v1/devices')
      .set(authed(token))
      .send({ fcmToken: 'token-abc', platform: 'ios' })
      .expect(201);
    const firstDevice = (first.body as DataEnvelope<DeviceResource>).data;

    const second = await request(app.getHttpServer())
      .post('/api/v1/devices')
      .set(authed(token))
      .send({ fcmToken: 'token-abc', platform: 'android' })
      .expect(201);
    const secondDevice = (second.body as DataEnvelope<DeviceResource>).data;

    expect(secondDevice.id).toBe(firstDevice.id);
    expect(secondDevice.platform).toBe('android');

    const rows: Array<{ count: string }> = await AppDataSource.query(
      `SELECT COUNT(*)::text AS count FROM devices WHERE user_id = $1 AND fcm_token = $2`,
      [userId, 'token-abc'],
    );
    expect(rows[0].count).toBe('1');
  });

  it('GET /notifications?unreadOnly=true returns only unread notifications', async () => {
    await AppDataSource.query(
      `INSERT INTO notifications (user_id, type, read_at) VALUES ($1, 'read_one', now())`,
      [userId],
    );
    const unread: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO notifications (user_id, type) VALUES ($1, 'unread_one') RETURNING id`,
      [userId],
    );

    const response = await request(app.getHttpServer())
      .get('/api/v1/notifications?unreadOnly=true')
      .set(authed(token))
      .expect(200);

    const body = response.body as DataEnvelope<NotificationResource[]>;
    expect(body.data.length).toBeGreaterThan(0);
    expect(
      body.data.every((notification) => notification.readAt === null),
    ).toBe(true);
    expect(
      body.data.some((notification) => notification.id === unread[0].id),
    ).toBe(true);
  });
});
