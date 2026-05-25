import 'package:poketto/core/config/app_config.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/budget_settings_storage.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/services/user_settings_service.dart';

class UserSettingsRepository {
  final UserSettingsService _userSettingsService;
  final TokenStorage _tokenStorage;
  final BudgetSettingsStorage _budgetSettingsStorage;

  const UserSettingsRepository({
    required UserSettingsService userSettingsService,
    required TokenStorage tokenStorage,
    required BudgetSettingsStorage budgetSettingsStorage,
  })  : _userSettingsService = userSettingsService,
        _tokenStorage = tokenStorage,
        _budgetSettingsStorage = budgetSettingsStorage;

  Future<double?> getDailyBudget({int? userId}) async {
    if (await _hasRemoteSession()) {
      try {
        final settings = await _userSettingsService.getSettings();
        final backendBudget = readDouble(settings['daily_budget']);
        if (backendBudget != null && backendBudget > 0) return backendBudget;
      } on ApiException catch (error) {
        if (!error.canUseLocalFallback) rethrow;
      }
    }

    final localBudget =
        await _budgetSettingsStorage.getDailyBudget(userId: userId);
    if (localBudget != null && localBudget > 0) return localBudget;
    return AppConfig.dailyBudget > 0 ? AppConfig.dailyBudget : null;
  }

  Future<void> setDailyBudget(double amount, {int? userId}) async {
    var savedRemotely = false;
    if (await _hasRemoteSession()) {
      try {
        await _userSettingsService.updateSettings({'daily_budget': amount});
        savedRemotely = true;
      } on ApiException catch (error) {
        if (!error.canUseLocalFallback) rethrow;
      }
    }

    await _budgetSettingsStorage.setDailyBudget(amount, userId: userId);
    if (!savedRemotely) {
      // Local fallback remains the secondary source when API is offline.
    }
  }

  Future<double> getBudgetWarningThreshold({int? userId}) async {
    if (await _hasRemoteSession()) {
      try {
        final settings = await _userSettingsService.getSettings();
        final backendThreshold =
            readDouble(settings['budget_warning_threshold']);
        if (backendThreshold != null &&
            backendThreshold > 0 &&
            backendThreshold < 100) {
          await _budgetSettingsStorage.setWarningThreshold(
            backendThreshold,
            userId: userId,
          );
          return backendThreshold;
        }
      } on ApiException catch (error) {
        if (!error.canUseLocalFallback) rethrow;
      }
    }

    return _budgetSettingsStorage.getWarningThreshold(userId: userId);
  }

  Future<void> setBudgetWarningThreshold(
    double threshold, {
    int? userId,
  }) async {
    var savedRemotely = false;
    if (await _hasRemoteSession()) {
      try {
        await _userSettingsService.updateSettings({
          'budget_warning_threshold': threshold,
        });
        savedRemotely = true;
      } on ApiException catch (error) {
        if (!error.canUseLocalFallback) rethrow;
      }
    }

    await _budgetSettingsStorage.setWarningThreshold(
      threshold,
      userId: userId,
    );
    if (!savedRemotely) {
      // Local fallback remains available when the API is offline.
    }
  }

  Future<bool> _hasRemoteSession() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}
