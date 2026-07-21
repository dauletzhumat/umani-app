import { HttpStatus, Injectable } from '@nestjs/common';
import { TransactionRepository } from '../../domain/repositories/transaction.repository';
import { Transaction } from '../../domain/entities/transaction.entity';
import { CategoryRepository } from '../../../categories/domain/repositories/category.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { UpdateTransactionDto } from '../../infrastructure/dto/update-transaction.dto';

@Injectable()
export class UpdateTransactionUseCase {
  constructor(
    private readonly transactionRepository: TransactionRepository,
    private readonly categoryRepository: CategoryRepository,
  ) {}

  async execute(
    userId: string,
    transactionId: string,
    dto: UpdateTransactionDto,
  ): Promise<Transaction> {
    const transaction =
      await this.transactionRepository.findById(transactionId);

    // Another user's transaction is masked as NOT_FOUND (08_API.md §5).
    if (!transaction || transaction.userId !== userId) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Transaction not found',
      );
    }

    if (dto.amount !== undefined && Number(dto.amount) <= 0) {
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'amount must be greater than 0',
        [{ field: 'amount', issue: 'must_be_positive' }],
      );
    }

    if (dto.categoryId) {
      const category = await this.categoryRepository.findById(dto.categoryId);
      if (
        !category ||
        (category.userId !== null && category.userId !== userId)
      ) {
        throw new AppException(
          HttpStatus.NOT_FOUND,
          'NOT_FOUND',
          'categoryId does not reference an existing category',
        );
      }
    }

    return this.transactionRepository.update(transactionId, {
      categoryId: dto.categoryId,
      amount: dto.amount,
      currency: dto.currency,
      type: dto.type,
      occurredAt: dto.occurredAt,
      note: dto.note,
    });
  }
}
