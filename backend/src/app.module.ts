import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { envValidationSchema } from './config/env-validation.schema';
import { HealthController } from './modules/health/health.controller';
import { UsersModule } from './modules/users/users.module';
import { AuthModule } from './modules/auth/auth.module';
import { CategoriesModule } from './modules/categories/categories.module';
import { AccountsModule } from './modules/accounts/accounts.module';
import { TransactionsModule } from './modules/transactions/transactions.module';
import { OcrModule } from './modules/ocr/ocr.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { BudgetsModule } from './modules/budgets/budgets.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validationSchema: envValidationSchema,
    }),
    // Powers TransactionCreatedEvent -> BudgetThresholdListener (T6.2) —
    // an in-process pub/sub, not a durable queue; fine for MVP scope
    // since the listener runs synchronously within the same request.
    EventEmitterModule.forRoot(),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('POSTGRES_HOST'),
        port: configService.get<number>('POSTGRES_PORT'),
        username: configService.get<string>('POSTGRES_USER'),
        password: configService.get<string>('POSTGRES_PASSWORD'),
        database: configService.get<string>('POSTGRES_DB'),
        autoLoadEntities: true,
        // Migrations are a controlled, manual step (see 06_Architecture.md §11)
        // — never run automatically on container start.
        migrationsRun: false,
        synchronize: false,
      }),
    }),
    UsersModule,
    AuthModule,
    CategoriesModule,
    AccountsModule,
    TransactionsModule,
    OcrModule,
    NotificationsModule,
    BudgetsModule,
  ],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}
