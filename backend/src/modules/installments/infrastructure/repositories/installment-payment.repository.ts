import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { InstallmentPayment } from '../../domain/entities/installment-payment.entity';
import { InstallmentPaymentRepository } from '../../domain/repositories/installment-payment.repository';

@Injectable()
export class TypeOrmInstallmentPaymentRepository implements InstallmentPaymentRepository {
  constructor(
    @InjectRepository(InstallmentPayment)
    private readonly repository: Repository<InstallmentPayment>,
  ) {}

  createMany(
    installmentId: string,
    payments: Array<{ dueDate: string; amount: string }>,
  ): Promise<InstallmentPayment[]> {
    return this.repository.save(
      payments.map((payment) => ({
        installmentId,
        dueDate: payment.dueDate,
        amount: payment.amount,
      })),
    );
  }

  findAllForInstallments(
    installmentIds: string[],
  ): Promise<InstallmentPayment[]> {
    if (installmentIds.length === 0) return Promise.resolve([]);
    return this.repository.find({
      where: { installmentId: In(installmentIds) },
      order: { dueDate: 'ASC' },
    });
  }
}
