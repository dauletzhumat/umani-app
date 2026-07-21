import { AppDataSource } from '../../src/database/data-source';
import { revertAllMigrations } from './migration-test-utils';

describe('Migration 0005_transactions (e2e)', () => {
  let userId: string;
  let accountId: string;

  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();

    const users: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1) RETURNING id`,
      ['+77041230000'],
    );
    userId = users[0].id;

    const accounts: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO accounts (user_id, type, name, currency) VALUES ($1, 'cash', 'Наличные', 'KZT') RETURNING id`,
      [userId],
    );
    accountId = accounts[0].id;
  });

  afterAll(async () => {
    await revertAllMigrations(AppDataSource);
    await AppDataSource.destroy();
  });

  it('accepts a transaction with a positive amount', async () => {
    const rows: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO transactions (user_id, account_id, amount, currency, type, occurred_at)
       VALUES ($1, $2, 1500.00, 'KZT', 'expense', CURRENT_DATE) RETURNING id`,
      [userId, accountId],
    );

    expect(rows).toHaveLength(1);
  });

  it('rejects a non-positive amount (chk_transactions_amount_positive)', async () => {
    await expect(
      AppDataSource.query(
        `INSERT INTO transactions (user_id, account_id, amount, currency, type, occurred_at)
         VALUES ($1, $2, 0, 'KZT', 'expense', CURRENT_DATE)`,
        [userId, accountId],
      ),
    ).rejects.toThrow(/chk_transactions_amount_positive/);

    await expect(
      AppDataSource.query(
        `INSERT INTO transactions (user_id, account_id, amount, currency, type, occurred_at)
         VALUES ($1, $2, -100, 'KZT', 'expense', CURRENT_DATE)`,
        [userId, accountId],
      ),
    ).rejects.toThrow(/chk_transactions_amount_positive/);
  });

  it('rejects a second transaction reusing the same receipt_scan_id (ux_transactions_receipt_scan)', async () => {
    const scans: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO receipt_scans (user_id, image_url) VALUES ($1, $2) RETURNING id`,
      [userId, 'https://example.com/receipt.jpg'],
    );
    const receiptScanId = scans[0].id;

    await AppDataSource.query(
      `INSERT INTO transactions (user_id, account_id, receipt_scan_id, amount, currency, type, source, occurred_at)
       VALUES ($1, $2, $3, 2500.00, 'KZT', 'expense', 'ocr', CURRENT_DATE)`,
      [userId, accountId, receiptScanId],
    );

    await expect(
      AppDataSource.query(
        `INSERT INTO transactions (user_id, account_id, receipt_scan_id, amount, currency, type, source, occurred_at)
         VALUES ($1, $2, $3, 999.00, 'KZT', 'expense', 'ocr', CURRENT_DATE)`,
        [userId, accountId, receiptScanId],
      ),
    ).rejects.toThrow(/ux_transactions_receipt_scan/);
  });
});
