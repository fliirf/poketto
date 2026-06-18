import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/services/user_settings_service.dart';

class UserSettingsRepository {
  final UserSettingsService _userSettingsService;
  final TokenStorage _tokenStorage;

  const UserSettingsRepository({
    required UserSettingsService userSettingsService,
    required TokenStorage tokenStorage,
  })  : _userSettingsService = userSettingsService,
        _tokenStorage = tokenStorage;

  Future<Map<String, dynamic>> getSettings({int? userId}) async {
    await _requireRemoteSession();
    return _userSettingsService.getSettings();
  }

  Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> values, {
    int? userId,
  }) async {
    await _requireRemoteSession();
    return _userSettingsService.updateSettings(values);
  }

  Future<double?> getDailyBudget({int? userId}) async {
    await _requireRemoteSession();
    final settings = await _userSettingsService.getSettings();
    final backendBudget = readDouble(settings['daily_budget']);
    if (backendBudget != null && backendBudget > 0) return backendBudget;
    return null;
  }

  Future<void> setDailyBudget(double amount, {int? userId}) async {
    await _requireRemoteSession();
    await _userSettingsService.updateSettings({'daily_budget': amount});
  }

  Future<double?> getMonthlyBudget({int? userId}) async {
    final settings = await getSettings(userId: userId);
    return readDouble(settings['monthly_budget']);
  }

  Future<String> getCurrency({int? userId}) async {
    final settings = await getSettings(userId: userId);
    return readString(settings['currency']) ?? 'IDR';
  }

  Future<bool> getNotificationEnabled({int? userId}) async {
    final settings = await getSettings(userId: userId);
    final value = settings['notification_enabled'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() != 'false';
  }

  Future<double> getBudgetWarningThreshold({int? userId}) async {
    await _requireRemoteSession();
    final settings = await _userSettingsService.getSettings();
    final backendThreshold = readDouble(settings['budget_warning_threshold']);
    if (backendThreshold != null &&
        backendThreshold > 0 &&
        backendThreshold < 100) {
      return backendThreshold;
    }

    return 80;
  }

  Future<void> setBudgetWarningThreshold(
    double threshold, {
    int? userId,
  }) async {
    await _requireRemoteSession();
    await _userSettingsService.updateSettings({
      'budget_warning_threshold': threshold,
    });
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
