import { MigrationInterface, QueryRunner } from 'typeorm';

export class Accounts1753000003000 implements MigrationInterface {
  name = 'Accounts1753000003000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE accounts (
          id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          type            account_type NOT NULL,
          name            VARCHAR(100) NOT NULL,
          currency        CHAR(3) NOT NULL,
          balance_cached  NUMERIC(18,2) NOT NULL DEFAULT 0,
          provider        VARCHAR(100),
          archived        BOOLEAN NOT NULL DEFAULT false,
          created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
          updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
          deleted_at      TIMESTAMPTZ,

          CONSTRAINT chk_accounts_currency CHECK (currency ~ '^[A-Z]{3}$')
      )
    `);

    await queryRunner.query(
      `CREATE INDEX ix_accounts_user_id ON accounts (user_id) WHERE deleted_at IS NULL`,
    );

    await queryRunner.query(`
      CREATE TRIGGER trg_accounts_updated_at BEFORE UPDATE ON accounts
          FOR EACH ROW EXECUTE FUNCTION set_updated_at()
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP TRIGGER IF EXISTS trg_accounts_updated_at ON accounts`,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS accounts`);
  }
}
