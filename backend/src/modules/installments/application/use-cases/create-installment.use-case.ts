import { HttpStatus, Injectable } from '@nestjs/common';
import { InstallmentRepository } from '../../domain/repositories/installment.repository';
import { InstallmentPaymentRepository } from '../../domain/repositories/installment-payment.repository';
import { PaymentScheduleGeneratorService } from '../services/payment-schedule-generator.service';
import { InstallmentPayment } from '../../domain/entities/installment-payment.entity';
import { Installment } from '../../domain/entities/installment.entity';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { CreateInstallmentDto } from '../../infrastructure/dto/create-installment.dto';

export interface CreatedInstallment extends Installment {
  payments: InstallmentPayment[];
}

@Injectable()
export class CreateInstallmentUseCase {
  constructor(
    private readonly installmentRepository: InstallmentRepository,
    private readonly installmentPaymentRepository: InstallmentPaymentRepository,
    private readonly paymentScheduleGeneratorService: PaymentScheduleGeneratorService,
  ) {}

  async execute(
    userId: string,
    dto: CreateInstallmentDto,
  ): Promise<CreatedInstallment> {
    if (Number(dto.totalAmount) <= 0) {
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'totalAmount must be greater than 0',
        [{ field: 'totalAmount', issue: 'must_be_positive' }],
      );
    }
    if (dto.installmentsCount <= 0) {
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'installmentsCount must be greater than 0',
        [{ field: 'installmentsCount', issue: 'must_be_positive' }],
      );
    }

    const installment = await this.installmentRepository.create({
      userId,
      merchant: dto.merchant,
      totalAmount: dto.totalAmount,
      installmentsCount: dto.installmentsCount,
      startDate: dto.startDate,
      provider: dto.provider ?? null,
    });

    const schedule = this.paymentScheduleGeneratorService.generate({
      totalAmount: dto.totalAmount,
      installmentsCount: dto.installmentsCount,
      startDate: dto.startDate,
    });
    const payments = await this.installmentPaymentRepository.createMany(
      installment.id,
      schedule,
    );

    return { ...installment, payments };
  }
}
