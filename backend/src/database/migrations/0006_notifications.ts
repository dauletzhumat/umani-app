import { MigrationInterface, QueryRunner } from 'typeorm';

export class Notifications1753000005000 implements MigrationInterface {
  name = 'Notifications1753000005000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE devices (
          id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          fcm_token       VARCHAR(255) NOT NULL,
          platform        device_platform NOT NULL,
          last_active_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
          created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

          CONSTRAINT uq_devices_user_token UNIQUE (user_id, fcm_token)
      )
    `);

    await queryRunner.query(
      `CREATE INDEX ix_devices_user_id ON devices (user_id)`,
    );

    await queryRunner.query(`
      CREATE TABLE notifications (
          id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          type        VARCHAR(50) NOT NULL,
          payload     JSONB NOT NULL DEFAULT '{}'::jsonb,
          sent_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
          read_at     TIMESTAMPTZ
      )
    `);

    await queryRunner.query(
      `CREATE INDEX ix_notifications_user_sent ON notifications (user_id, sent_at DESC)`,
    );
    await queryRunner.query(
      `CREATE INDEX ix_notifications_user_unread ON notifications (user_id) WHERE read_at IS NULL`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS notifications`);
    await queryRunner.query(`DROP TABLE IF EXISTS devices`);
  }
}
