import { MigrationInterface, QueryRunner } from 'typeorm';

const ENUM_TYPES: Array<{ name: string; values: string[] }> = [
  { name: 'account_type', values: ['cash', 'bank', 'card', 'multi_currency'] },
  { name: 'transaction_type', values: ['income', 'expense'] },
  {
    name: 'transaction_source',
    values: ['manual', 'ocr', 'voice', 'import'],
  },
  { name: 'budget_period', values: ['weekly', 'monthly'] },
  {
    name: 'installment_payment_status',
    values: ['pending', 'paid', 'overdue'],
  },
  {
    name: 'asset_type',
    values: ['deposit', 'real_estate', 'stock', 'crypto', 'gold', 'other'],
  },
  { name: 'family_role', values: ['full', 'view'] },
  { name: 'ai_message_role', values: ['user', 'assistant', 'system'] },
  { name: 'device_platform', values: ['ios', 'android'] },
  { name: 'payment_provider', values: ['apple', 'google', 'kaspi'] },
  {
    name: 'premium_status',
    values: [
      'trial',
      'active',
      'grace_period',
      'canceled_pending_expiry',
      'expired',
    ],
  },
  {
    name: 'recurring_periodicity',
    values: ['weekly', 'monthly', 'quarterly', 'yearly'],
  },
];

export class InitExtensionsAndEnums1753000000000 implements MigrationInterface {
  name = 'InitExtensionsAndEnums1753000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS pgcrypto`);

    await queryRunner.query(`
      CREATE OR REPLACE FUNCTION set_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = now();
          RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);

    for (const enumType of ENUM_TYPES) {
      const values = enumType.values.map((value) => `'${value}'`).join(', ');
      await queryRunner.query(
        `CREATE TYPE ${enumType.name} AS ENUM (${values})`,
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    for (const enumType of [...ENUM_TYPES].reverse()) {
      await queryRunner.query(`DROP TYPE IF EXISTS ${enumType.name}`);
    }

    await queryRunner.query(`DROP FUNCTION IF EXISTS set_updated_at()`);

    await queryRunner.query(`DROP EXTENSION IF EXISTS pgcrypto`);
  }
}
