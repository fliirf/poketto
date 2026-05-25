import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_client.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/data/models/category_model.dart';

class CategoryService {
  final ApiClient _apiClient;

  const CategoryService(this._apiClient);

  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.get('/categories');
    final items = readListPayload(response, const ['categories']);
    return items
        .map((item) => CategoryModel.fromJson(asStringDynamicMap(item)))
        .toList();
  }

  Future<CategoryModel> createCategory(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/categories', body: payload);
    return CategoryModel.fromJson(readMapPayload(response, const ['category']));
  }

  Future<CategoryModel> updateCategory(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiClient.put('/categories/$id', body: payload);
      return CategoryModel.fromJson(
          readMapPayload(response, const ['category']));
    } on ApiException catch (error) {
      if (error.statusCode != 405) rethrow;
      final response = await _apiClient.patch('/categories/$id', body: payload);
      return CategoryModel.fromJson(
          readMapPayload(response, const ['category']));
    }
  }

  Future<void> updateCategoryBudget(
    int categoryId,
    double monthlyBudget,
  ) async {
    final payload = {
      'monthly_budget': monthlyBudget,
      'budget_limit': monthlyBudget,
      'budget': monthlyBudget,
      'limit': monthlyBudget,
    };

    try {
      await _apiClient.put('/categories/$categoryId', body: payload);
    } on ApiException catch (error) {
      if (error.statusCode != 405) rethrow;
      await _apiClient.patch('/categories/$categoryId', body: payload);
    }
  }

  Future<void> deleteCategory(int id) async {
    await _apiClient.delete('/categories/$id');
  }
}
