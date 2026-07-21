import 'dotenv/config';
import { DataSource } from 'typeorm';
import { User } from '../modules/users/domain/entities/user.entity';
import { RefreshToken } from '../modules/auth/domain/entities/refresh-token.entity';
import { OtpCode } from '../modules/auth/domain/entities/otp-code.entity';
import { Category } from '../modules/categories/domain/entities/category.entity';
import { Account } from '../modules/accounts/domain/entities/account.entity';

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.POSTGRES_HOST ?? 'localhost',
  port: Number(process.env.POSTGRES_PORT ?? 5432),
  username: process.env.POSTGRES_USER ?? 'ai_finance',
  password: process.env.POSTGRES_PASSWORD ?? 'ai_finance',
  database: process.env.POSTGRES_DB ?? 'ai_finance',
  entities: [User, RefreshToken, OtpCode, Category, Account],
  migrations: [__dirname + '/migrations/*.{ts,js}'],
});
