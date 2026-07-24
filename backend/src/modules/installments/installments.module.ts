import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Installment } from './domain/entities/installment.entity';
import { InstallmentPayment } from './domain/entities/installment-payment.entity';
import { InstallmentRepository } from './domain/repositories/installment.repository';
import { TypeOrmInstallmentRepository } from './infrastructure/repositories/installment.repository';
import { InstallmentPaymentRepository } from './domain/repositories/installment-payment.repository';
import { TypeOrmInstallmentPaymentRepository } from './infrastructure/repositories/installment-payment.repository';
import { PaymentScheduleGeneratorService } from './application/services/payment-schedule-generator.service';
import { CreateInstallmentUseCase } from './application/use-cases/create-installment.use-case';
import { GetInstallmentsUseCase } from './application/use-cases/get-installments.use-case';
import { MarkPaymentPaidUseCase } from './application/use-cases/mark-payment-paid.use-case';
import { InstallmentsController } from './infrastructure/controllers/installments.controller';
import { InstallmentReminderJob } from './infrastructure/jobs/installment-reminder.job';
import { UsersModule } from '../users/users.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  // NotificationsModule gives InstallmentReminderJob
  // NotificationDispatcherService + NotificationRepository (T7.3);
  // UsersModule gives it the user's locale for the push text — same
  // shape BudgetsModule already uses for BudgetThresholdListener (T6.2).
  imports: [
    TypeOrmModule.forFeature([Installment, InstallmentPayment]),
    UsersModule,
    NotificationsModule,
  ],
  controllers: [InstallmentsController],
  providers: [
    { provide: InstallmentRepository, useClass: TypeOrmInstallmentRepository },
    {
      provide: InstallmentPaymentRepository,
      useClass: TypeOrmInstallmentPaymentRepository,
    },
    PaymentScheduleGeneratorService,
    CreateInstallmentUseCase,
    GetInstallmentsUseCase,
    MarkPaymentPaidUseCase,
    InstallmentReminderJob,
  ],
  exports: [InstallmentRepository, InstallmentPaymentRepository],
})
export class InstallmentsModule {}
