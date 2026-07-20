import 'dotenv/config';
import { DataSource } from 'typeorm';

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.POSTGRES_HOST ?? 'localhost',
  port: Number(process.env.POSTGRES_PORT ?? 5432),
  username: process.env.POSTGRES_USER ?? 'ai_finance',
  password: process.env.POSTGRES_PASSWORD ?? 'ai_finance',
  database: process.env.POSTGRES_DB ?? 'ai_finance',
  entities: [],
  migrations: [__dirname + '/migrations/*.{ts,js}'],
});
