import { MigrationInterface, QueryRunner } from 'typeorm';

export class UsersAuth1753000001000 implements MigrationInterface {
  name = 'UsersAuth1753000001000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE users (
          id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          phone               VARCHAR(20) UNIQUE,
          email               VARCHAR(255) UNIQUE,
          name                VARCHAR(100),
          locale              VARCHAR(5) NOT NULL DEFAULT 'ru',
          default_currency    CHAR(3) NOT NULL DEFAULT 'KZT',
          created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
          updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
          deleted_at          TIMESTAMPTZ,

          CONSTRAINT chk_users_phone_format CHECK (phone IS NULL OR phone ~ '^\\+[1-9][0-9]{7,14}$'),
          CONSTRAINT chk_users_email_format CHECK (email IS NULL OR email ~ '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$'),
          CONSTRAINT chk_users_has_identifier CHECK (phone IS NOT NULL OR email IS NOT NULL),
          CONSTRAINT chk_users_locale CHECK (locale IN ('ru', 'kk', 'en'))
      )
    `);

    await queryRunner.query(
      `CREATE UNIQUE INDEX ux_users_phone ON users (phone) WHERE deleted_at IS NULL`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX ux_users_email ON users (lower(email)) WHERE deleted_at IS NULL AND email IS NOT NULL`,
    );

    await queryRunner.query(`
      CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
          FOR EACH ROW EXECUTE FUNCTION set_updated_at()
    `);

    await queryRunner.query(`
      CREATE TABLE refresh_tokens (
          id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          token_hash      VARCHAR(255) NOT NULL,
          device_id       UUID,
          issued_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
          expires_at      TIMESTAMPTZ NOT NULL,
          revoked_at      TIMESTAMPTZ,

          CONSTRAINT uq_refresh_tokens_hash UNIQUE (token_hash),
          CONSTRAINT chk_refresh_tokens_expiry CHECK (expires_at > issued_at)
      )
    `);

    await queryRunner.query(
      `CREATE INDEX ix_refresh_tokens_user_id ON refresh_tokens (user_id)`,
    );
    await queryRunner.query(
      `CREATE INDEX ix_refresh_tokens_expires_at ON refresh_tokens (expires_at) WHERE revoked_at IS NULL`,
    );

    await queryRunner.query(`
      CREATE TABLE otp_codes (
          id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          identifier      VARCHAR(255) NOT NULL,
          code_hash       VARCHAR(255) NOT NULL,
          attempts        SMALLINT NOT NULL DEFAULT 0,
          created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
          expires_at      TIMESTAMPTZ NOT NULL,
          used_at         TIMESTAMPTZ,

          CONSTRAINT chk_otp_attempts CHECK (attempts >= 0 AND attempts <= 5)
      )
    `);

    await queryRunner.query(
      `CREATE INDEX ix_otp_codes_identifier ON otp_codes (identifier, expires_at DESC)`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS otp_codes`);
    await queryRunner.query(`DROP TABLE IF EXISTS refresh_tokens`);
    await queryRunner.query(
      `DROP TRIGGER IF EXISTS trg_users_updated_at ON users`,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS users`);
  }
}
