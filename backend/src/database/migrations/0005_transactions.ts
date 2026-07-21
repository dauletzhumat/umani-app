import { MigrationInterface, QueryRunner } from 'typeorm';

export class Transactions1753000004000 implements MigrationInterface {
  name = 'Transactions1753000004000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE receipt_scans (
          id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          image_url       TEXT NOT NULL,
          raw_ocr_json    JSONB,
          status          VARCHAR(20) NOT NULL DEFAULT 'pending',
          created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

          CONSTRAINT chk_receipt_scans_status CHECK (status IN ('pending', 'processed', 'failed'))
      )
    `);

    await queryRunner.query(
      `CREATE INDEX ix_receipt_scans_user_id ON receipt_scans (user_id, created_at DESC)`,
    );

    await queryRunner.query(`
      CREATE TABLE transactions (
          id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          account_id          UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
          category_id         UUID REFERENCES categories(id) ON DELETE SET NULL,
          receipt_scan_id     UUID REFERENCES receipt_scans(id) ON DELETE SET NULL,
          amount              NUMERIC(18,2) NOT NULL,
          currency            CHAR(3) NOT NULL,
          type                transaction_type NOT NULL,
          source              transaction_source NOT NULL DEFAULT 'manual',
          occurred_at         DATE NOT NULL,
          note                VARCHAR(500),
          created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
          updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
          deleted_at          TIMESTAMPTZ,

          CONSTRAINT chk_transactions_amount_positive CHECK (amount > 0),
          CONSTRAINT chk_transactions_currency CHECK (currency ~ '^[A-Z]{3}$')
      )
    `);

    await queryRunner.query(
      `CREATE INDEX ix_transactions_user_occurred ON transactions (user_id, occurred_at DESC) WHERE deleted_at IS NULL`,
    );
    await queryRunner.query(
      `CREATE INDEX ix_transactions_account_occurred ON transactions (account_id, occurred_at DESC) WHERE deleted_at IS NULL`,
    );
    await queryRunner.query(
      `CREATE INDEX ix_transactions_category ON transactions (category_id) WHERE deleted_at IS NULL`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX ux_transactions_receipt_scan ON transactions (receipt_scan_id) WHERE receipt_scan_id IS NOT NULL`,
    );

    await queryRunner.query(`
      CREATE TRIGGER trg_transactions_updated_at BEFORE UPDATE ON transactions
          FOR EACH ROW EXECUTE FUNCTION set_updated_at()
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP TRIGGER IF EXISTS trg_transactions_updated_at ON transactions`,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS transactions`);
    await queryRunner.query(`DROP TABLE IF EXISTS receipt_scans`);
  }
}
