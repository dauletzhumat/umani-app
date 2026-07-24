import { Injectable } from '@nestjs/common';
import { BudgetRepository } from '../../domain/repositories/budget.repository';
import { CategoryRepository } from '../../../categories/domain/repositories/category.repository';
import {
  BudgetProgress,
  BudgetProgressService,
} from '../services/budget-progress.service';

@Injectable()
export class GetBudgetsUseCase {
  constructor(
    private readonly budgetRepository: BudgetRepository,
    private readonly categoryRepository: CategoryRepository,
    private readonly budgetProgressService: BudgetProgressService,
  ) {}

  async execute(userId: string): Promise<BudgetProgress[]> {
    const budgets = await this.budgetRepository.findAllForUser(userId);

    return Promise.all(
      budgets.map(async (budget) => {
        const category = await this.categoryRepository.findById(
          budget.categoryId,
        );
        return this.budgetProgressService.computeProgress(
          budget,
          category?.name ?? '',
        );
      }),
    );
  }
}
