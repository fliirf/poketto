import 'package:poketto/core/config/app_config.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/models/dashboard_summary_model.dart';
import 'package:poketto/data/repositories/budget_alert_repository.dart';
import 'package:poketto/data/services/dashboard_service.dart';

class DashboardRepository {
  final DashboardService _dashboardService;
  final BudgetAlertRepository _budgetAlertRepository;
  final TokenStorage _tokenStorage;

  const DashboardRepository({
    required DashboardService dashboardService,
    required BudgetAlertRepository budgetAlertRepository,
    required TokenStorage tokenStorage,
  })  : _dashboardService = dashboardService,
        _budgetAlertRepository = budgetAlertRepository,
        _tokenStorage = tokenStorage;

  Future<DashboardSummaryModel> getSummary(int userId) async {
    await _requireRemoteSession();

    final summary = await _dashboardService.getSummary();
    final dailyBudget = _resolveDailyBudget(summary.dailyBudget);
    final alerts = _budgetAlertRepository.mergeAlerts(
      summary.alerts,
      await _budgetAlertRepository.getRemoteAlerts(),
    );

    return DashboardSummaryModel(
      totalIncome: summary.totalIncome,
      totalExpense: summary.totalExpense,
      balance: summary.balance,
      dailyBudget: dailyBudget,
      monthlyBudget: summary.monthlyBudget,
      expenseTrend: summary.expenseTrend,
      categoryBreakdown: summary.categoryBreakdown,
      recentTransactions: summary.recentTransactions,
      alerts: alerts,
    );
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

  double? _resolveDailyBudget(double? backendDailyBudget) {
    if (backendDailyBudget != null && backendDailyBudget > 0) {
      return backendDailyBudget;
    }

    return AppConfig.dailyBudget > 0 ? AppConfig.dailyBudget : null;
  }
}
