import { HttpStatus, Injectable } from '@nestjs/common';
import { BudgetRepository } from '../../domain/repositories/budget.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';

@Injectable()
export class DeleteBudgetUseCase {
  constructor(private readonly budgetRepository: BudgetRepository) {}

  async execute(userId: string, id: string): Promise<void> {
    const budget = await this.budgetRepository.findById(id);
    if (!budget || budget.userId !== userId) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Budget not found',
      );
    }

    await this.budgetRepository.softDelete(id);
  }
}
