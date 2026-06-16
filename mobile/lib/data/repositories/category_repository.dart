import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/services/category_service.dart';

class CategoryRepository {
  final CategoryService _categoryService;
  final TokenStorage _tokenStorage;

  const CategoryRepository({
    required CategoryService categoryService,
    required TokenStorage tokenStorage,
  })  : _categoryService = categoryService,
        _tokenStorage = tokenStorage;

  Future<List<Map<String, dynamic>>> getCategoriesForUi({
    String? type,
    int? userId,
  }) async {
    await _requireRemoteSession();

    final categories = await _categoryService.getCategories();
    final filtered = type == null
        ? categories
        : categories.where((category) => category.type == type).toList();
    return filtered.map((category) => category.toUiMap()).toList();
  }

  Future<int> createCategoryForUi({
    required String name,
    required String type,
    double? monthlyBudget,
    int? userId,
  }) async {
    await _requireRemoteSession();

    final created = await _categoryService.createCategory(
      _categoryPayload(
        name: name,
        type: type,
        monthlyBudget: monthlyBudget,
      ),
    );
    return created.id > 0 ? created.id : 1;
  }

  Future<int> updateCategoryForUi({
    required int categoryId,
    required String name,
    required String type,
    double? monthlyBudget,
    int? userId,
  }) async {
    await _requireRemoteSession();

    await _categoryService.updateCategory(
      categoryId,
      _categoryPayload(
        name: name,
        type: type,
        monthlyBudget: monthlyBudget,
      ),
    );
    return 1;
  }

  Future<void> updateCategoryBudget({
    required int categoryId,
    required double monthlyBudget,
    int? userId,
  }) async {
    await _requireRemoteSession();
    await _categoryService.updateCategoryBudget(
      categoryId,
      monthlyBudget,
    );
  }

  Future<int> deleteCategoryForUi(int categoryId) async {
    await _requireRemoteSession();
    await _categoryService.deleteCategory(categoryId);
    return 1;
  }

  Map<String, dynamic> _categoryPayload({
    required String name,
    required String type,
    double? monthlyBudget,
  }) {
    return {
      'name': name,
      'type': type,
      'monthly_budget': monthlyBudget,
      'budget_limit': monthlyBudget,
      'budget': monthlyBudget,
      'limit': monthlyBudget,
    }..removeWhere((key, value) => value == null);
  }

  Future<void> _requireRemoteSession() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Sesi berakhir. Silakan login ulang.',
        statusCode: 401,
      );
    }
  }
}
