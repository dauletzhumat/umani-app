import { MigrationInterface, QueryRunner } from 'typeorm';

export class Budgets1753000006000 implements MigrationInterface {
  name = 'Budgets1753000006000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE budgets (
          id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          category_id     UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
          amount_limit    NUMERIC(18,2) NOT NULL,
          period          budget_period NOT NULL DEFAULT 'monthly',
          start_date      DATE NOT NULL,
          created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
          updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
          deleted_at      TIMESTAMPTZ,

          CONSTRAINT chk_budgets_amount_positive CHECK (amount_limit > 0)
      )
    `);

    await queryRunner.query(
      `CREATE INDEX ix_budgets_user_id ON budgets (user_id) WHERE deleted_at IS NULL`,
    );
    await queryRunner.query(
      `CREATE INDEX ix_budgets_category_id ON budgets (category_id)`,
    );
    // A plain table CONSTRAINT (docs/07_Database.md §5.8's literal form)
    // would keep colliding with a soft-deleted row forever — a deleted
    // budget could never be recreated for the same category/period/start.
    // Partial index instead, same shape as ux_transactions_receipt_scan.
    await queryRunner.query(
      `CREATE UNIQUE INDEX uq_budgets_user_category_period ON budgets (user_id, category_id, period, start_date) WHERE deleted_at IS NULL`,
    );

    await queryRunner.query(`
      CREATE TRIGGER trg_budgets_updated_at BEFORE UPDATE ON budgets
          FOR EACH ROW EXECUTE FUNCTION set_updated_at()
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP TRIGGER IF EXISTS trg_budgets_updated_at ON budgets`,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS budgets`);
  }
}
