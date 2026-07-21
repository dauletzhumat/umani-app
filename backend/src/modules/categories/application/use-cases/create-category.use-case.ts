import { HttpStatus, Injectable } from '@nestjs/common';
import { CategoryRepository } from '../../domain/repositories/category.repository';
import { Category } from '../../domain/entities/category.entity';
import { AppException } from '../../../../shared/exceptions/app.exception';
import { CreateCategoryDto } from '../../infrastructure/dto/create-category.dto';

@Injectable()
export class CreateCategoryUseCase {
  constructor(private readonly categoryRepository: CategoryRepository) {}

  async execute(userId: string, dto: CreateCategoryDto): Promise<Category> {
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

    if (dto.parentId) {
      const parent = await this.categoryRepository.findById(dto.parentId);
      if (!parent) {
        throw new AppException(
          HttpStatus.NOT_FOUND,
          'NOT_FOUND',
          'parentId does not reference an existing category',
        );
      }
    }

    return this.categoryRepository.create({
      userId,
      name: dto.name,
      icon: dto.icon,
      parentId: dto.parentId ?? null,
    });
  }
}
