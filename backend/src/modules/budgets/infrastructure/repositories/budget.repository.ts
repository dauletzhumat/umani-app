import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { Budget, BudgetPeriod } from '../../domain/entities/budget.entity';
import { BudgetRepository } from '../../domain/repositories/budget.repository';

@Injectable()
export class TypeOrmBudgetRepository implements BudgetRepository {
  constructor(
    @InjectRepository(Budget)
    private readonly repository: Repository<Budget>,
  ) {}

  findAllForUser(userId: string): Promise<Budget[]> {
    return this.repository.find({
      where: { userId, deletedAt: IsNull() },
    });
  }

  findById(id: string): Promise<Budget | null> {
    return this.repository.findOne({ where: { id, deletedAt: IsNull() } });
  }

  findAllForUserAndCategory(
    userId: string,
    categoryId: string,
  ): Promise<Budget[]> {
    return this.repository.find({
      where: { userId, categoryId, deletedAt: IsNull() },
    });
  }

  findByUserCategoryPeriodAndStart(
    userId: string,
    categoryId: string,
    period: BudgetPeriod,
    startDate: string,
  ): Promise<Budget | null> {
    return this.repository.findOne({
      where: { userId, categoryId, period, startDate, deletedAt: IsNull() },
    });
  }

  create(data: {
    userId: string;
    categoryId: string;
    amountLimit: string;
    period: BudgetPeriod;
    startDate: string;
  }): Promise<Budget> {
    return this.repository.save({
      userId: data.userId,
      categoryId: data.categoryId,
      amountLimit: data.amountLimit,
      period: data.period,
      startDate: data.startDate,
    });
  }

  async update(
    id: string,
    changes: { amountLimit?: string; period?: BudgetPeriod },
  ): Promise<Budget> {
    await this.repository.update({ id }, changes);
    const updated = await this.repository.findOne({ where: { id } });
    if (!updated) {
      throw new Error('Budget disappeared during update');
    }
    return updated;
  }

  async softDelete(id: string): Promise<void> {
    await this.repository.update({ id }, { deletedAt: new Date() });
  }
}
