import { AppDataSource } from '../../src/database/data-source';
import { revertAllMigrations } from './migration-test-utils';

describe('Migration 0004_accounts (e2e)', () => {
  let userId: string;

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const rows: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1) RETURNING id`,
      ['+77021230000'],
    );
    userId = rows[0].id;
  });

  afterAll(async () => {
    await revertAllMigrations(AppDataSource);
    await AppDataSource.destroy();
  });

  it('accepts an account with a valid currency', async () => {
    const rows: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO accounts (user_id, type, name, currency) VALUES ($1, 'cash', 'Наличные', 'KZT') RETURNING id`,
      [userId],
    );

    expect(rows).toHaveLength(1);
  });

  it('rejects an invalid currency code (chk_accounts_currency)', async () => {
    await expect(
      AppDataSource.query(
        `INSERT INTO accounts (user_id, type, name, currency) VALUES ($1, 'cash', 'Наличные', 'kzt')`,
        [userId],
      ),
    ).rejects.toThrow(/chk_accounts_currency/);

    await expect(
      AppDataSource.query(
        `INSERT INTO accounts (user_id, type, name, currency) VALUES ($1, 'cash', 'Наличные', 'KZ')`,
        [userId],
      ),
    ).rejects.toThrow(/chk_accounts_currency/);
  });
});
