import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/models/budget_alert_model.dart';
import 'package:poketto/data/services/budget_alert_service.dart';

class BudgetAlertRepository {
  final BudgetAlertService _budgetAlertService;
  final TokenStorage _tokenStorage;

  const BudgetAlertRepository({
    required BudgetAlertService budgetAlertService,
    required TokenStorage tokenStorage,
  })  : _budgetAlertService = budgetAlertService,
        _tokenStorage = tokenStorage;

  Future<List<BudgetAlertModel>> getAlerts({
    required double totalIncome,
    required double totalExpense,
    required List<Map<String, dynamic>> transactions,
    double? dailyBudget,
    List<Map<String, dynamic>> categories = const [],
    Map<String, dynamic>? activeTarget,
    Map<String, dynamic>? targetProgress,
  }) async {
    return getRemoteAlerts();
  }

  Future<List<BudgetAlertModel>> getRemoteAlerts() async {
    await _requireRemoteSession();

    return _budgetAlertService.getAlerts();
  }

  List<BudgetAlertModel> mergeAlerts(
    List<BudgetAlertModel> primary,
    List<BudgetAlertModel> secondary,
  ) {
    final seen = <String>{};
    final merged = <BudgetAlertModel>[];

    for (final alert in [...primary, ...secondary]) {
      final key = '${alert.alertType}:${alert.message}';
      if (seen.add(key)) merged.add(alert);
    }

    return merged;
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
