import 'package:shared_preferences/shared_preferences.dart';

class BudgetSettingsStorage {
  static const String _globalDailyBudgetKey = 'daily_budget';
  static const String _globalWarningThresholdKey = 'budget_warning_threshold';
  static const String _categoryBudgetPrefix = 'category_monthly_budget';

  Future<double?> getDailyBudget({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _dailyBudgetKey(userId);

    if (prefs.containsKey(userKey)) {
      return _readDouble(prefs.get(userKey));
    }

    return _readDouble(prefs.get(_globalDailyBudgetKey));
  }

  Future<void> setDailyBudget(double amount, {int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dailyBudgetKey(userId), amount);
  }

  Future<double> getWarningThreshold({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _warningThresholdKey(userId);

    final value = prefs.containsKey(userKey)
        ? _readDouble(prefs.get(userKey))
        : _readDouble(prefs.get(_globalWarningThresholdKey));

    if (value == null || value <= 0 || value >= 100) return 80;
    return value;
  }

  Future<void> setWarningThreshold(double threshold, {int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_warningThresholdKey(userId), threshold);
  }

  Future<double?> getCategoryMonthlyBudget(
    int categoryId, {
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _categoryBudgetKey(categoryId, userId);

    if (prefs.containsKey(userKey)) {
      return _readDouble(prefs.get(userKey));
    }

    return _readDouble(prefs.get(_categoryBudgetKey(categoryId, null)));
  }

  Future<void> setCategoryMonthlyBudget(
    int categoryId,
    double? amount, {
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _categoryBudgetKey(categoryId, userId);

    if (amount == null || amount <= 0) {
      await prefs.remove(key);
      return;
    }

    await prefs.setDouble(key, amount);
  }

  String _dailyBudgetKey(int? userId) {
    return userId == null ? _globalDailyBudgetKey : 'daily_budget_user_$userId';
  }

  String _warningThresholdKey(int? userId) {
    return userId == null
        ? _globalWarningThresholdKey
        : 'budget_warning_threshold_user_$userId';
  }

  String _categoryBudgetKey(int categoryId, int? userId) {
    final base = '${_categoryBudgetPrefix}_$categoryId';
    return userId == null ? base : '${base}_user_$userId';
  }

  double? _readDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }
}
