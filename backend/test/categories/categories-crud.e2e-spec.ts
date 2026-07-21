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

interface CategoryResource {
  id: string;
  userId: string | null;
  name: string;
  icon: string;
}

describe('Categories CRUD (e2e)', () => {
  let app: INestApplication<App>;
  let user1Id: string;
  let user2Id: string;
  let user1Token: string;
  let user2Token: string;
  let systemCategoryId: string;

  function authed(token: string) {
    return { Authorization: `Bearer ${token}` };
  }

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const users: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1), ($2) RETURNING id`,
      ['+77071110000', '+77071110001'],
    );
    user1Id = users[0].id;
    user2Id = users[1].id;

    const systemCategories: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO categories (user_id, name, icon) VALUES (NULL, $1, $2) RETURNING id`,
      ['Тестовая системная', 'category'],
    );
    systemCategoryId = systemCategories[0].id;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    setupApp(app);
    await app.init();

    const jwtService = new JwtService({ secret: process.env.JWT_SECRET });
    user1Token = jwtService.sign({
      sub: user1Id,
      scope: 'full',
      premiumStatus: 'trial',
    });
    user2Token = jwtService.sign({
      sub: user2Id,
      scope: 'full',
      premiumStatus: 'trial',
    });
  });

  afterAll(async () => {
    await app.close();
    await revertAllMigrations(AppDataSource);
    await AppDataSource.destroy();
  });

  it('GET /categories returns system categories for a user with none of their own', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/categories')
      .set(authed(user1Token))
      .expect(200);

    const body = response.body as DataEnvelope<CategoryResource[]>;
    expect(body.data.some((c) => c.id === systemCategoryId)).toBe(true);
  });

  it('POST /categories creates a custom category owned by the caller', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/categories')
      .set(authed(user1Token))
      .send({ name: 'Хобби', icon: 'brush' })
      .expect(201);

    const body = response.body as DataEnvelope<CategoryResource>;
    expect(body.data.name).toBe('Хобби');
    expect(body.data.userId).toBe(user1Id);
  });

  it('creating a category with a name already used by another user does not conflict', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/categories')
      .set(authed(user2Token))
      .send({ name: 'Хобби', icon: 'brush' })
      .expect(201);
  });

  it('creating a second category with the same name for the same user returns 409 CONFLICT', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/categories')
      .set(authed(user1Token))
      .send({ name: 'Хобби', icon: 'brush' })
      .expect(409);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('CONFLICT');
  });

  it('PATCH on a system category returns 403 FORBIDDEN_ROLE', async () => {
    const response = await request(app.getHttpServer())
      .patch(`/api/v1/categories/${systemCategoryId}`)
      .set(authed(user1Token))
      .send({ name: 'Переименовано' })
      .expect(403);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('FORBIDDEN_ROLE');
  });

  it('DELETE on a system category returns 403 FORBIDDEN_ROLE', async () => {
    const response = await request(app.getHttpServer())
      .delete(`/api/v1/categories/${systemCategoryId}`)
      .set(authed(user1Token))
      .expect(403);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('FORBIDDEN_ROLE');
  });

  it("PATCH on another user's category returns 404", async () => {
    const createResponse = await request(app.getHttpServer())
      .post('/api/v1/categories')
      .set(authed(user2Token))
      .send({ name: 'Только для user2', icon: 'lock' })
      .expect(201);
    const other = (createResponse.body as DataEnvelope<CategoryResource>).data;

    const response = await request(app.getHttpServer())
      .patch(`/api/v1/categories/${other.id}`)
      .set(authed(user1Token))
      .send({ name: 'Захват' })
      .expect(404);

    const body = response.body as ErrorEnvelope;
    expect(body.error.code).toBe('NOT_FOUND');
  });

  it('PATCH/DELETE update and remove an own category; deleted category disappears from GET', async () => {
    const createResponse = await request(app.getHttpServer())
      .post('/api/v1/categories')
      .set(authed(user1Token))
      .send({ name: 'Временная', icon: 'delete' })
      .expect(201);
    const created = (createResponse.body as DataEnvelope<CategoryResource>)
      .data;

    const patchResponse = await request(app.getHttpServer())
      .patch(`/api/v1/categories/${created.id}`)
      .set(authed(user1Token))
      .send({ name: 'Переименованная' })
      .expect(200);
    expect(
      (patchResponse.body as DataEnvelope<CategoryResource>).data.name,
    ).toBe('Переименованная');

    await request(app.getHttpServer())
      .delete(`/api/v1/categories/${created.id}`)
      .set(authed(user1Token))
      .expect(204);

    const listResponse = await request(app.getHttpServer())
      .get('/api/v1/categories')
      .set(authed(user1Token))
      .expect(200);
    const list = (listResponse.body as DataEnvelope<CategoryResource[]>).data;
    expect(list.some((c) => c.id === created.id)).toBe(false);
  });
});
