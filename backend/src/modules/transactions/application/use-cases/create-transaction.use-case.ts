import { HttpStatus, Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { TransactionRepository } from '../../domain/repositories/transaction.repository';
import { Transaction } from '../../domain/entities/transaction.entity';
import {
  TRANSACTION_CREATED_EVENT,
  TransactionCreatedEvent,
} from '../../domain/events/transaction-created.event';
import { AccountRepository } from '../../../accounts/domain/repositories/account.repository';
import { CategoryRepository } from '../../../categories/domain/repositories/category.repository';
import { RecalculateAccountBalanceService } from '../../../accounts/application/services/recalculate-account-balance.service';
import { CategorizationService } from '../../../ai/infrastructure/services/categorization.service';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { CreateTransactionDto } from '../../infrastructure/dto/create-transaction.dto';

@Injectable()
export class CreateTransactionUseCase {
  constructor(
    private readonly transactionRepository: TransactionRepository,
    private readonly accountRepository: AccountRepository,
    private readonly categoryRepository: CategoryRepository,
    private readonly recalculateAccountBalanceService: RecalculateAccountBalanceService,
    private readonly categorizationService: CategorizationService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async execute(
    userId: string,
    dto: CreateTransactionDto,
  ): Promise<Transaction> {
    if (Number(dto.amount) <= 0) {
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'amount must be greater than 0',
        [{ field: 'amount', issue: 'must_be_positive' }],
      );
    }

    const account = await this.accountRepository.findById(dto.accountId);
    if (!account || account.userId !== userId) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'accountId does not reference an existing account',
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

    // Auto-categorize only when the client didn't pick one and there's a
    // note to categorize from — the schema has no dedicated "merchant"
    // column, so note is the only textual signal available (T4.4).
    let categoryId = dto.categoryId ?? null;
    if (!categoryId && dto.note) {
      categoryId = await this.categorizationService.categorize({
        userId,
        merchant: dto.note,
        amount: dto.amount,
        currency: dto.currency,
      });
    }

    const transaction = await this.transactionRepository.create({
      userId,
      accountId: dto.accountId,
      categoryId,
      amount: dto.amount,
      currency: dto.currency,
      type: dto.type,
      source: dto.source ?? 'manual',
      occurredAt: dto.occurredAt ?? new Date().toISOString().slice(0, 10),
      note: dto.note ?? null,
    });

    await this.recalculateAccountBalanceService.recalculate(dto.accountId);

    // emitAsync (not emit) so the response only returns once
    // BudgetThresholdListener (T6.2) has finished — makes the budget
    // notification reliably exist by the time the client sees 201,
    // rather than racing a fire-and-forget background listener. The
    // listener itself catches its own errors, so this can't turn a
    // notification failure into a failed transaction creation.
    await this.eventEmitter.emitAsync(
      TRANSACTION_CREATED_EVENT,
      new TransactionCreatedEvent(
        userId,
        transaction.categoryId,
        transaction.type,
        transaction.occurredAt,
      ),
    );

    return transaction;
  }
}
