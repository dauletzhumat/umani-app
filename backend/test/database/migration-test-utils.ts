import { DataSource } from 'typeorm';

async function countAppliedMigrations(dataSource: DataSource): Promise<number> {
  const rows: Array<{ count: number }> = await dataSource.query(
    `SELECT (CASE WHEN to_regclass('public.migrations') IS NULL
                  THEN 0
                  ELSE (SELECT COUNT(*) FROM migrations) END)::int AS count`,
  );
  return rows[0]?.count ?? 0;
}

/**
 * Reverts every applied migration, not just the last one. Needed because
 * runMigrations() always runs all pending migrations in a shared DataSource
 * (see data-source.ts's `migrations` glob) — a single undoLastMigration()
 * only undoes the newest one once more than one migration file exists.
 */
export async function revertAllMigrations(
  dataSource: DataSource,
): Promise<void> {
  for (let i = 0; i < dataSource.migrations.length; i++) {
    if ((await countAppliedMigrations(dataSource)) === 0) {
      return;
    }
    await dataSource.undoLastMigration();
  }
}
