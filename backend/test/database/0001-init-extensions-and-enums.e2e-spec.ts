import { AppDataSource } from '../../src/database/data-source';

async function extensionExists(name: string): Promise<boolean> {
  const rows: unknown[] = await AppDataSource.query(
    'SELECT 1 FROM pg_extension WHERE extname = $1',
    [name],
  );
  return rows.length > 0;
}

async function enumTypeExists(name: string): Promise<boolean> {
  const rows: unknown[] = await AppDataSource.query(
    "SELECT 1 FROM pg_type WHERE typname = $1 AND typtype = 'e'",
    [name],
  );
  return rows.length > 0;
}

async function functionExists(name: string): Promise<boolean> {
  const rows: unknown[] = await AppDataSource.query(
    'SELECT 1 FROM pg_proc WHERE proname = $1',
    [name],
  );
  return rows.length > 0;
}

describe('Migration 0001_init_extensions_and_enums (e2e)', () => {
  beforeAll(async () => {
    await AppDataSource.initialize();
  });

  afterAll(async () => {
    await AppDataSource.destroy();
  });

  it('up() creates pgcrypto, set_updated_at() and ENUM types without errors; down() reverts cleanly', async () => {
    await expect(AppDataSource.runMigrations()).resolves.not.toThrow();

    await expect(extensionExists('pgcrypto')).resolves.toBe(true);
    await expect(functionExists('set_updated_at')).resolves.toBe(true);
    await expect(enumTypeExists('account_type')).resolves.toBe(true);
    await expect(enumTypeExists('recurring_periodicity')).resolves.toBe(true);

    await expect(AppDataSource.undoLastMigration()).resolves.not.toThrow();

    await expect(enumTypeExists('account_type')).resolves.toBe(false);
    await expect(enumTypeExists('recurring_periodicity')).resolves.toBe(false);
    await expect(functionExists('set_updated_at')).resolves.toBe(false);
    await expect(extensionExists('pgcrypto')).resolves.toBe(false);
  });
});
