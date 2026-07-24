import { HttpStatus, Injectable } from '@nestjs/common';
import { InstallmentRepository } from '../../domain/repositories/installment.repository';
import { InstallmentPaymentRepository } from '../../domain/repositories/installment-payment.repository';
import { InstallmentPayment } from '../../domain/entities/installment-payment.entity';
import { AppException } from '../../../../shared/exceptions/app.exception';

@Injectable()
export class MarkPaymentPaidUseCase {
  constructor(
    private readonly installmentRepository: InstallmentRepository,
    private readonly installmentPaymentRepository: InstallmentPaymentRepository,
  ) {}

  async execute(
    userId: string,
    installmentId: string,
    paymentId: string,
  ): Promise<InstallmentPayment> {
    const installment =
      await this.installmentRepository.findById(installmentId);
    if (!installment || installment.userId !== userId) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Installment not found',
      );
    }

    const payment = await this.installmentPaymentRepository.findById(paymentId);
    if (!payment || payment.installmentId !== installmentId) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Payment not found',
      );
    }

    // Marking an already-paid payment paid again is a harmless no-op —
    // only this one row is ever touched, never siblings in the schedule.
    return this.installmentPaymentRepository.markPaid(paymentId);
  }
}
