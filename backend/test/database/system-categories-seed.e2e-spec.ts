import { AppDataSource } from '../../src/database/data-source';
import {
  SYSTEM_CATEGORIES,
  seedSystemCategories,
} from '../../src/database/seeds/system-categories.seed';
import { revertAllMigrations } from './migration-test-utils';

describe('System categories seed (e2e)', () => {
  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();
  });

  afterAll(async () => {
    await revertAllMigrations(AppDataSource);
    await AppDataSource.destroy();
  });

  it('is idempotent: running twice does not create duplicates', async () => {
    await seedSystemCategories(AppDataSource);
    await seedSystemCategories(AppDataSource);

    const rows: Array<{ count: number }> = await AppDataSource.query(
      `SELECT COUNT(*)::int AS count FROM categories WHERE user_id IS NULL`,
    );

    expect(rows[0]?.count).toBe(SYSTEM_CATEGORIES.length);
  });
});
