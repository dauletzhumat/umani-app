import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Category } from './domain/entities/category.entity';
import { CategoryRepository } from './domain/repositories/category.repository';
import { TypeOrmCategoryRepository } from './infrastructure/repositories/category.repository';
import { CreateCategoryUseCase } from './application/use-cases/create-category.use-case';
import { UpdateCategoryUseCase } from './application/use-cases/update-category.use-case';
import { DeleteCategoryUseCase } from './application/use-cases/delete-category.use-case';
import { CategoriesController } from './infrastructure/controllers/categories.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Category])],
  controllers: [CategoriesController],
  providers: [
    { provide: CategoryRepository, useClass: TypeOrmCategoryRepository },
    CreateCategoryUseCase,
    UpdateCategoryUseCase,
    DeleteCategoryUseCase,
  ],
  exports: [CategoryRepository],
})
export class CategoriesModule {}
