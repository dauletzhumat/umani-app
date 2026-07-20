import { AppDataSource } from '../../src/database/data-source';
import { revertAllMigrations } from './migration-test-utils';

describe('Migration 0002_users_auth (e2e)', () => {
  beforeAll(async () => {
    await AppDataSource.initialize();
    await AppDataSource.runMigrations();
  });

  afterAll(async () => {
    await revertAllMigrations(AppDataSource);
    await AppDataSource.destroy();
  });

  it('accepts a user with an identifier', async () => {
    const rows: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO users (phone) VALUES ($1) RETURNING id`,
      ['+77011234567'],
    );

    expect(rows).toHaveLength(1);
  });

  it('rejects a user with neither phone nor email (chk_users_has_identifier)', async () => {
    await expect(
      AppDataSource.query(
        `INSERT INTO users (phone, email) VALUES (NULL, NULL)`,
      ),
    ).rejects.toThrow(/chk_users_has_identifier/);
  });

  it('rejects the 6th otp attempt (chk_otp_attempts)', async () => {
    await expect(
      AppDataSource.query(
        `INSERT INTO otp_codes (identifier, code_hash, attempts, expires_at)
         VALUES ($1, $2, 6, now() + interval '5 minutes')`,
        ['+77011234567', 'hash'],
      ),
    ).rejects.toThrow(/chk_otp_attempts/);

    const rows: Array<{ id: string }> = await AppDataSource.query(
      `INSERT INTO otp_codes (identifier, code_hash, attempts, expires_at)
       VALUES ($1, $2, 5, now() + interval '5 minutes')
       RETURNING id`,
      ['+77011234567', 'hash'],
    );

    expect(rows).toHaveLength(1);
  });
});
