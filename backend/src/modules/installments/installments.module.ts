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
import { InstallmentsController } from './infrastructure/controllers/installments.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Installment, InstallmentPayment])],
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
  ],
  exports: [InstallmentRepository, InstallmentPaymentRepository],
})
export class InstallmentsModule {}
