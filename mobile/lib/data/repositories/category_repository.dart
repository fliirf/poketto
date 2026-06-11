import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/budget_settings_storage.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/models/category_model.dart';
import 'package:poketto/data/services/category_service.dart';
import 'package:poketto/database/database_helper.dart';

class CategoryRepository {
  final CategoryService _categoryService;
  final TokenStorage _tokenStorage;
  final DatabaseHelper _databaseHelper;
  final BudgetSettingsStorage _budgetSettingsStorage;

  const CategoryRepository({
    required CategoryService categoryService,
    required TokenStorage tokenStorage,
    required DatabaseHelper databaseHelper,
    required BudgetSettingsStorage budgetSettingsStorage,
  })  : _categoryService = categoryService,
        _tokenStorage = tokenStorage,
        _databaseHelper = databaseHelper,
        _budgetSettingsStorage = budgetSettingsStorage;

  Future<List<Map<String, dynamic>>> getCategoriesForUi({
    String? type,
    int? userId,
  }) async {
    if (await _hasRemoteSession()) {
      try {
        final categories = await _categoryService.getCategories();
        final filtered = type == null
            ? categories
            : categories.where((category) => category.type == type).toList();
        return _withStoredBudgets(
          filtered.map((category) => category.toUiMap()).toList(),
          userId: userId,
        );
      } on ApiException catch (error) {
        if (!error.canUseLocalFallback) rethrow;
      }
    }

    // TODO: Remove SQLite/default category fallback once GET /categories is stable.
    return _localCategoriesForUi(type: type, userId: userId);
  }

  Future<int> createCategoryForUi({
    required String name,
    required String type,
    double? monthlyBudget,
    int? userId,
  }) async {
    if (await _hasRemoteSession()) {
      final payload = _categoryPayload(
        name: name,
        type: type,
        monthlyBudget: monthlyBudget,
      );

      try {
        final created = await _categoryService.createCategory(payload);
        if (created.id > 0 && monthlyBudget != null && monthlyBudget > 0) {
          await _budgetSettingsStorage.setCategoryMonthlyBudget(
            created.id,
            monthlyBudget,
            userId: userId,
          );
        }
        return created.id > 0 ? created.id : 1;
      } on ApiException catch (error) {
        if (!_shouldRetryWithoutBudget(error, monthlyBudget)) {
          if (!error.canUseLocalFallback) rethrow;
        } else {
          try {
            final created = await _categoryService.createCategory(
              _categoryPayload(name: name, type: type),
            );
            if (created.id > 0 && monthlyBudget != null && monthlyBudget > 0) {
              await _budgetSettingsStorage.setCategoryMonthlyBudget(
                created.id,
                monthlyBudget,
                userId: userId,
              );
            }
            return created.id > 0 ? created.id : 1;
          } on ApiException catch (retryError) {
            if (!retryError.canUseLocalFallback) rethrow;
          }
        }
      }
    }

    return _databaseHelper.createCategory(
      name,
      type,
      monthlyBudget: monthlyBudget,
    );
  }

  Future<int> updateCategoryForUi({
    required int categoryId,
    required String name,
    required String type,
    double? monthlyBudget,
    int? userId,
  }) async {
    if (await _hasRemoteSession()) {
      final payload = _categoryPayload(
        name: name,
        type: type,
        monthlyBudget: monthlyBudget,
      );

      try {
        await _categoryService.updateCategory(categoryId, payload);
        await _budgetSettingsStorage.setCategoryMonthlyBudget(
          categoryId,
          monthlyBudget,
          userId: userId,
        );
        return 1;
      } on ApiException catch (error) {
        if (_shouldRetryWithoutBudget(error, monthlyBudget)) {
          try {
            await _categoryService.updateCategory(
              categoryId,
              _categoryPayload(name: name, type: type),
            );
            await _budgetSettingsStorage.setCategoryMonthlyBudget(
              categoryId,
              monthlyBudget,
              userId: userId,
            );
            return 1;
          } on ApiException catch (retryError) {
            if (!retryError.canUseLocalFallback) rethrow;
          }
        } else if (!error.canUseLocalFallback) {
          rethrow;
        }
      }
    }

    final result = await _databaseHelper.updateCategory(
      categoryId,
      name,
      monthlyBudget: monthlyBudget,
    );
    await _budgetSettingsStorage.setCategoryMonthlyBudget(
      categoryId,
      monthlyBudget,
      userId: userId,
    );
    return result > 0 || categoryId > 0 ? 1 : result;
  }

  Future<void> updateCategoryBudget({
    required int categoryId,
    required double monthlyBudget,
    int? userId,
  }) async {
    if (await _hasRemoteSession()) {
      try {
        await _categoryService.updateCategoryBudget(
          categoryId,
          monthlyBudget,
        );
      } on ApiException catch (error) {
        if (!error.canUseLocalFallback &&
            error.statusCode != 400 &&
            error.statusCode != 422) {
          rethrow;
        }
      }
    }

    await _budgetSettingsStorage.setCategoryMonthlyBudget(
      categoryId,
      monthlyBudget,
      userId: userId,
    );
    await _databaseHelper.updateCategoryMonthlyBudget(
      categoryId,
      monthlyBudget,
    );
  }

  Future<int> deleteCategoryForUi(int categoryId) async {
    if (await _hasRemoteSession()) {
      try {
        await _categoryService.deleteCategory(categoryId);
        return 1;
      } on ApiException catch (error) {
        if (!error.canUseLocalFallback) rethrow;
      }
    }

    return _databaseHelper.deleteCategory(categoryId);
  }

  Future<bool> _hasRemoteSession() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> _localCategoriesForUi(
      {String? type, int? userId}) async {
    final categories = type == null
        ? await _databaseHelper.getAllCategories()
        : await _databaseHelper.getCategoriesByType(type);

    if (categories.isNotEmpty) {
      return _withStoredBudgets(categories, userId: userId);
    }

    await _ensureFallbackCategories();
    final fallbackCategories = type == null
        ? _databaseHelper.getAllCategories()
        : _databaseHelper.getCategoriesByType(type);
    return _withStoredBudgets(await fallbackCategories, userId: userId);
  }

  Future<void> _ensureFallbackCategories() async {
    const fallback = [
      CategoryModel(id: 0, name: 'Gaji', type: 'income'),
      CategoryModel(id: 0, name: 'Bonus', type: 'income'),
      CategoryModel(id: 0, name: 'Makanan', type: 'expense'),
      CategoryModel(id: 0, name: 'Transportasi', type: 'expense'),
      CategoryModel(id: 0, name: 'Hiburan', type: 'expense'),
      CategoryModel(id: 0, name: 'Pendidikan', type: 'expense'),
      CategoryModel(id: 0, name: 'Kesehatan', type: 'expense'),
      CategoryModel(id: 0, name: 'Lainnya', type: 'expense'),
    ];

    for (final category in fallback) {
      await _databaseHelper.createCategory(category.name, category.type);
    }
  }

  Future<List<Map<String, dynamic>>> _withStoredBudgets(
    List<Map<String, dynamic>> categories, {
    int? userId,
  }) async {
    final result = <Map<String, dynamic>>[];

    for (final category in categories) {
      final categoryId = readInt(category['category_id'] ?? category['id']);
      final apiBudget = readDouble(
        category['monthly_budget'] ??
            category['monthlyBudget'] ??
            category['budget'] ??
            category['limit'] ??
            category['budget_limit'] ??
            category['budgetLimit'],
      );
      final storedBudget = categoryId == null
          ? null
          : await _budgetSettingsStorage.getCategoryMonthlyBudget(
              categoryId,
              userId: userId,
            );
      final effectiveBudget =
          apiBudget != null && apiBudget > 0 ? apiBudget : storedBudget;

      result.add({
        ...category,
        if (effectiveBudget != null && effectiveBudget > 0)
          'monthly_budget': effectiveBudget,
      });
    }

    return result;
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

  bool _shouldRetryWithoutBudget(ApiException error, double? monthlyBudget) {
    return monthlyBudget != null &&
        monthlyBudget > 0 &&
        (error.statusCode == 400 || error.statusCode == 422);
  }
}
