import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

/// Raw HTTP calls to /categories (docs/08_API.md §9) folded directly into
/// the repository — no separate datasource file, same self-contained
/// style as InitialSetupRepository (T1.12).
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Category>> fetchAll() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/categories');
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<Category> create({
    required String name,
    required String icon,
    String? parentId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/categories',
        data: {
          'name': name,
          'icon': icon,
          'parentId': ?parentId,
        },
      );
      return Category.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(apiClientProvider));
});

final categoryListProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).fetchAll();
});
