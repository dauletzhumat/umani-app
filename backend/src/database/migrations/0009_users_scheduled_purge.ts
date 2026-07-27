import { MigrationInterface, QueryRunner } from 'typeorm';

export class UsersScheduledPurge1753000008000 implements MigrationInterface {
  name = 'UsersScheduledPurge1753000008000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE users ADD COLUMN scheduled_purge_at TIMESTAMPTZ`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE users DROP COLUMN IF EXISTS scheduled_purge_at`,
    );
  }
}
