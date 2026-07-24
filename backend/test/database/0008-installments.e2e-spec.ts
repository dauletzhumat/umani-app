import { AppDataSource } from '../../src/database/data-source';
import { revertAllMigrations } from './migration-test-utils';

describe('Migration 0008_installments (e2e)', () => {
  let userId: string;

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const rows: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1) RETURNING id`,
      ['+77081230000'],
    );
    userId = rows[0].id;
  });

  afterAll(async () => {
    await revertAllMigrations(AppDataSource);
    await AppDataSource.destroy();
  });

  it('accepts an installment with a positive total_amount and installments_count', async () => {
    const rows: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO installments (user_id, merchant, total_amount, installments_count, start_date)
       VALUES ($1, 'Technodom', 120000.00, 12, '2026-07-01') RETURNING id`,
      [userId],
    );

    expect(rows).toHaveLength(1);
  });

  it('rejects a non-positive total_amount (chk_installments_total_positive)', async () => {
    await expect(
      AppDataSource.query(
        `INSERT INTO installments (user_id, merchant, total_amount, installments_count, start_date)
         VALUES ($1, 'Technodom', 0, 12, '2026-07-01')`,
        [userId],
      ),
    ).rejects.toThrow(/chk_installments_total_positive/);
  });

  it('rejects a non-positive installments_count (chk_installments_count_positive)', async () => {
    await expect(
      AppDataSource.query(
        `INSERT INTO installments (user_id, merchant, total_amount, installments_count, start_date)
         VALUES ($1, 'Technodom', 120000.00, 0, '2026-07-01')`,
        [userId],
      ),
    ).rejects.toThrow(/chk_installments_count_positive/);
  });

  it('rejects a non-positive installment_payments.amount (chk_installment_payments_amount)', async () => {
    const installments: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO installments (user_id, merchant, total_amount, installments_count, start_date)
       VALUES ($1, 'Technodom', 120000.00, 12, '2026-07-01') RETURNING id`,
      [userId],
    );

    await expect(
      AppDataSource.query(
        `INSERT INTO installment_payments (installment_id, due_date, amount) VALUES ($1, '2026-08-01', 0)`,
        [installments[0].id],
      ),
    ).rejects.toThrow(/chk_installment_payments_amount/);
  });
});
