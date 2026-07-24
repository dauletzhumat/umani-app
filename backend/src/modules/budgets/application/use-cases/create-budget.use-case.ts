import { HttpStatus, Injectable } from '@nestjs/common';
import { BudgetRepository } from '../../domain/repositories/budget.repository';
import { CategoryRepository } from '../../../categories/domain/repositories/category.repository';
import {
  BudgetProgress,
  BudgetProgressService,
} from '../services/budget-progress.service';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { CreateBudgetDto } from '../../infrastructure/dto/create-budget.dto';

@Injectable()
export class CreateBudgetUseCase {
  constructor(
    private readonly budgetRepository: BudgetRepository,
    private readonly categoryRepository: CategoryRepository,
    private readonly budgetProgressService: BudgetProgressService,
  ) {}

  async execute(userId: string, dto: CreateBudgetDto): Promise<BudgetProgress> {
    if (Number(dto.amountLimit) <= 0) {
      throw new AppException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'amountLimit must be greater than 0',
        [{ field: 'amountLimit', issue: 'must_be_positive' }],
      );
    }

    const category = await this.categoryRepository.findById(dto.categoryId);
    if (!category || (category.userId !== null && category.userId !== userId)) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'categoryId does not reference an existing category',
      );
    }

    const period = dto.period ?? 'monthly';
    const existing =
      await this.budgetRepository.findByUserCategoryPeriodAndStart(
        userId,
        dto.categoryId,
        period,
        dto.startDate,
      );
    if (existing) {
      throw new AppException(
        HttpStatus.CONFLICT,
        'CONFLICT',
        'A budget for this category/period already exists',
      );
    }

    const budget = await this.budgetRepository.create({
      userId,
      categoryId: dto.categoryId,
      amountLimit: dto.amountLimit,
      period,
      startDate: dto.startDate,
    });

    return this.budgetProgressService.computeProgress(budget, category.name);
  }
}
