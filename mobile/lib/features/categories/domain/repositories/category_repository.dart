import '../entities/category.dart';

abstract class CategoryRepository {
  /// GET /categories — system categories plus the caller's own.
  Future<List<Category>> fetchAll();

  /// POST /categories — creates a custom category owned by the caller.
  Future<Category> create({
    required String name,
    required String icon,
    String? parentId,
  });
}
