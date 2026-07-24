import { HttpStatus, Injectable } from '@nestjs/common';
import { BudgetRepository } from '../../domain/repositories/budget.repository';
import { CategoryRepository } from '../../../categories/domain/repositories/category.repository';
import {
  BudgetProgress,
  BudgetProgressService,
} from '../services/budget-progress.service';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { UpdateBudgetDto } from '../../infrastructure/dto/update-budget.dto';

@Injectable()
export class UpdateBudgetUseCase {
  constructor(
    private readonly budgetRepository: BudgetRepository,
    private readonly categoryRepository: CategoryRepository,
    private readonly budgetProgressService: BudgetProgressService,
  ) {}

  async execute(
    userId: string,
    id: string,
    dto: UpdateBudgetDto,
  ): Promise<BudgetProgress> {
    const budget = await this.budgetRepository.findById(id);
    if (!budget || budget.userId !== userId) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Budget not found',
      );
    }

    if (dto.amountLimit !== undefined && Number(dto.amountLimit) <= 0) {
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'amountLimit must be greater than 0',
        [{ field: 'amountLimit', issue: 'must_be_positive' }],
      );
    }

    if (dto.period !== undefined && dto.period !== budget.period) {
      const existing =
        await this.budgetRepository.findByUserCategoryPeriodAndStart(
          userId,
          budget.categoryId,
          dto.period,
          budget.startDate,
        );
      if (existing) {
        throw new AppException(
          HttpStatus.CONFLICT,
          'CONFLICT',
          'A budget for this category/period already exists',
        );
      }
    }

    const updated = await this.budgetRepository.update(id, {
      amountLimit: dto.amountLimit,
      period: dto.period,
    });

    const category = await this.categoryRepository.findById(updated.categoryId);
    return this.budgetProgressService.computeProgress(
      updated,
      category?.name ?? '',
    );
  }
}
