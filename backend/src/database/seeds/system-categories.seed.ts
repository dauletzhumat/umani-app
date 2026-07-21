import { DataSource } from 'typeorm';
import { AppDataSource } from '../data-source';

interface SystemCategorySeed {
  name: string;
  icon: string;
}

/**
 * No canonical list exists in the docs — a reasonable MVP taxonomy for a
 * RU/KZ Kazakhstan audience (docs/01_PRD.md mentions local specifics like
 * "той"/ЖКХ as examples of what generic trackers miss).
 *
 * `name` is the canonical Russian label (docs/07_Database.md §5.4 has a
 * single `name` column, not per-locale ones) — Kazakh display translation
 * is a client-side concern (T2.3's category picker), same pattern as
 * mobile/lib/core/localization/app_localizations.dart. `icon` is a plain
 * key (e.g. 'shopping_cart'), mapped to a Flutter IconData client-side.
 */
export const SYSTEM_CATEGORIES: SystemCategorySeed[] = [
  { name: 'Продукты', icon: 'shopping_cart' },
  { name: 'Транспорт', icon: 'directions_car' },
  { name: 'ЖКХ и коммуналка', icon: 'home' },
  { name: 'Рестораны и кафе', icon: 'restaurant' },
  { name: 'Здоровье', icon: 'local_hospital' },
  { name: 'Одежда и обувь', icon: 'checkroom' },
  { name: 'Развлечения', icon: 'celebration' },
  { name: 'Связь и интернет', icon: 'wifi' },
  { name: 'Образование', icon: 'school' },
  { name: 'Красота и уход', icon: 'spa' },
  { name: 'Подарки и той', icon: 'card_giftcard' },
  { name: 'Рассрочки и кредиты', icon: 'credit_card' },
  { name: 'Зарплата', icon: 'payments' },
  { name: 'Прочий доход', icon: 'attach_money' },
  { name: 'Прочее', icon: 'category' },
];

/** Idempotent: targets the partial unique index directly, so a repeated run is a no-op. */
export async function seedSystemCategories(
  dataSource: DataSource = AppDataSource,
): Promise<void> {
  for (const category of SYSTEM_CATEGORIES) {
    await dataSource.query(
      `INSERT INTO categories (user_id, name, icon)
       VALUES (NULL, $1, $2)
       ON CONFLICT (name) WHERE user_id IS NULL AND deleted_at IS NULL DO NOTHING`,
      [category.name, category.icon],
    );
  }
}

async function run(): Promise<void> {
  await AppDataSource.initialize();
  await seedSystemCategories();
  await AppDataSource.destroy();
}

if (require.main === module) {
  void run();
}
