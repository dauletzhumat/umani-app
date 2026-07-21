import { HttpStatus, Injectable } from '@nestjs/common';
import { CategoryRepository } from '../../domain/repositories/category.repository';
import { Category } from '../../domain/entities/category.entity';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { UpdateCategoryDto } from '../../infrastructure/dto/update-category.dto';

@Injectable()
export class UpdateCategoryUseCase {
  constructor(private readonly categoryRepository: CategoryRepository) {}

  async execute(
    userId: string,
    categoryId: string,
    dto: UpdateCategoryDto,
  ): Promise<Category> {
    const category = await this.categoryRepository.findById(categoryId);

    // A different user's category is masked as NOT_FOUND (08_API.md §5); a
    // system one is a known, visible resource, so it gets an explicit 403.
    if (!category || (category.userId !== null && category.userId !== userId)) {
      throw new AppException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Category not found',
      );
    }
    if (category.userId === null) {
      throw new AppException(
        HttpStatus.FORBIDDEN,
        'FORBIDDEN_ROLE',
        'System categories cannot be modified',
      );
    }

    if (dto.name && dto.name !== category.name) {
      const existing = await this.categoryRepository.findByUserAndName(
        userId,
        dto.name,
      );
      if (existing) {
        throw new AppException(
          HttpStatus.CONFLICT,
          'CONFLICT',
          'You already have a category with this name',
        );
      }
    }

    if (dto.parentId) {
      if (dto.parentId === categoryId) {
        throw new AppException(
          HttpStatus.UNPROCESSABLE_ENTITY,
          'UNPROCESSABLE_BUSINESS_RULE',
          'A category cannot be its own parent',
        );
      }
      const parent = await this.categoryRepository.findById(dto.parentId);
      if (!parent) {
        throw new AppException(
          HttpStatus.NOT_FOUND,
          'NOT_FOUND',
          'parentId does not reference an existing category',
        );
      }
    }

    return this.categoryRepository.update(categoryId, {
      name: dto.name,
      icon: dto.icon,
      parentId: dto.parentId,
    });
  }
}
