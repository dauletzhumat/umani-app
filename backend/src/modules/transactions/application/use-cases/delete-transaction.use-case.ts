import { HttpStatus, Injectable } from '@nestjs/common';
import { TransactionRepository } from '../../domain/repositories/transaction.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';

@Injectable()
export class DeleteTransactionUseCase {
  constructor(private readonly transactionRepository: TransactionRepository) {}

  async execute(userId: string, transactionId: string): Promise<void> {
    const transaction =
      await this.transactionRepository.findById(transactionId);

    if (!transaction || transaction.userId !== userId) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Transaction not found',
      );
    }

    await this.transactionRepository.softDelete(transactionId);
  }
}
