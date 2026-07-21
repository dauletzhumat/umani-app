import { Category } from '../entities/category.entity';

export abstract class CategoryRepository {
  /** System categories (user_id IS NULL) plus this user's own, not soft-deleted. */
  abstract findAllForUser(userId: string): Promise<Category[]>;

  abstract findById(id: string): Promise<Category | null>;

  abstract findByUserAndName(
    userId: string,
    name: string,
  ): Promise<Category | null>;

  abstract create(data: {
    userId: string;
    name: string;
    icon: string;
    parentId: string | null;
  }): Promise<Category>;

  abstract update(
    id: string,
    changes: { name?: string; icon?: string; parentId?: string | null },
  ): Promise<Category>;

  abstract softDelete(id: string): Promise<void>;
}
