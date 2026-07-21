import { HttpStatus, Injectable } from '@nestjs/common';
import { CategoryRepository } from '../../domain/repositories/category.repository';
import { AppException } from '../../../../shared/exceptions/app.exception';

@Injectable()
export class DeleteCategoryUseCase {
  constructor(private readonly categoryRepository: CategoryRepository) {}

  async execute(userId: string, categoryId: string): Promise<void> {
    const category = await this.categoryRepository.findById(categoryId);

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
        'System categories cannot be deleted',
      );
    }

    await this.categoryRepository.softDelete(categoryId);
  }
}
