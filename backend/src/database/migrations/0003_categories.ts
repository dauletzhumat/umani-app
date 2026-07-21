import { MigrationInterface, QueryRunner } from 'typeorm';

export class Categories1753000002000 implements MigrationInterface {
  name = 'Categories1753000002000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE categories (
          id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
          parent_id   UUID REFERENCES categories(id) ON DELETE SET NULL,
          name        VARCHAR(100) NOT NULL,
          icon        VARCHAR(50) NOT NULL,
          created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
          deleted_at  TIMESTAMPTZ
      )
    `);

    await queryRunner.query(
      `CREATE UNIQUE INDEX ux_categories_system_name ON categories (name) WHERE user_id IS NULL AND deleted_at IS NULL`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX ux_categories_user_name ON categories (user_id, name) WHERE user_id IS NOT NULL AND deleted_at IS NULL`,
    );
    await queryRunner.query(
      `CREATE INDEX ix_categories_parent_id ON categories (parent_id)`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS categories`);
  }
}
