import { MigrationInterface, QueryRunner } from 'typeorm';

export class Installments1753000007000 implements MigrationInterface {
  name = 'Installments1753000007000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE installments (
          id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          merchant            VARCHAR(150) NOT NULL,
          total_amount        NUMERIC(18,2) NOT NULL,
          installments_count  SMALLINT NOT NULL,
          start_date          DATE NOT NULL,
          provider            VARCHAR(100),
          created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
          updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
          deleted_at          TIMESTAMPTZ,

          CONSTRAINT chk_installments_total_positive CHECK (total_amount > 0),
          CONSTRAINT chk_installments_count_positive CHECK (installments_count > 0)
      )
    `);

    await queryRunner.query(
      `CREATE INDEX ix_installments_user_id ON installments (user_id) WHERE deleted_at IS NULL`,
    );

    await queryRunner.query(`
      CREATE TRIGGER trg_installments_updated_at BEFORE UPDATE ON installments
          FOR EACH ROW EXECUTE FUNCTION set_updated_at()
    `);

    await queryRunner.query(`
      CREATE TABLE installment_payments (
          id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          installment_id  UUID NOT NULL REFERENCES installments(id) ON DELETE CASCADE,
          due_date        DATE NOT NULL,
          amount          NUMERIC(18,2) NOT NULL,
          status          installment_payment_status NOT NULL DEFAULT 'pending',
          paid_at         TIMESTAMPTZ,
          created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

          CONSTRAINT chk_installment_payments_amount CHECK (amount > 0)
      )
    `);

    await queryRunner.query(
      `CREATE INDEX ix_installment_payments_installment_id ON installment_payments (installment_id, due_date)`,
    );
    // For the daily reminder cron job (06_Architecture.md §12).
    await queryRunner.query(
      `CREATE INDEX ix_installment_payments_due_pending ON installment_payments (due_date) WHERE status = 'pending'`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS installment_payments`);
    await queryRunner.query(
      `DROP TRIGGER IF EXISTS trg_installments_updated_at ON installments`,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS installments`);
  }
}
