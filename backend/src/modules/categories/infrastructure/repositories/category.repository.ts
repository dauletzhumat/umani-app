import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { Category } from '../../domain/entities/category.entity';
import { CategoryRepository } from '../../domain/repositories/category.repository';

@Injectable()
export class TypeOrmCategoryRepository implements CategoryRepository {
  constructor(
    @InjectRepository(Category)
    private readonly repository: Repository<Category>,
  ) {}

  findAllForUser(userId: string): Promise<Category[]> {
    return this.repository
      .createQueryBuilder('category')
      .where('category.deletedAt IS NULL')
      .andWhere('(category.userId IS NULL OR category.userId = :userId)', {
        userId,
      })
      .orderBy('category.name', 'ASC')
      .getMany();
  }

  findById(id: string): Promise<Category | null> {
    return this.repository.findOne({ where: { id, deletedAt: IsNull() } });
  }

  findByUserAndName(userId: string, name: string): Promise<Category | null> {
    return this.repository.findOne({
      where: { userId, name, deletedAt: IsNull() },
    });
  }

  create(data: {
    userId: string;
    name: string;
    icon: string;
    parentId: string | null;
  }): Promise<Category> {
    return this.repository.save({
      userId: data.userId,
      name: data.name,
      icon: data.icon,
      parentId: data.parentId,
    });
  }

  async update(
    id: string,
    changes: { name?: string; icon?: string; parentId?: string | null },
  ): Promise<Category> {
    await this.repository.update({ id }, changes);
    const updated = await this.repository.findOne({ where: { id } });
    if (!updated) {
      throw new Error('Category disappeared during update');
    }
    return updated;
  }

  async softDelete(id: string): Promise<void> {
    await this.repository.update({ id }, { deletedAt: new Date() });
  }
}
