import 'package:intl/intl.dart';
import 'package:poketto/core/config/app_config.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/core/storage/budget_settings_storage.dart';
import 'package:poketto/core/storage/token_storage.dart';
import 'package:poketto/data/models/dashboard_summary_model.dart';
import 'package:poketto/data/models/transaction_model.dart';
import 'package:poketto/data/repositories/budget_alert_repository.dart';
import 'package:poketto/data/repositories/category_repository.dart';
import 'package:poketto/data/services/dashboard_service.dart';
import 'package:poketto/database/database_helper.dart';

class DashboardRepository {
  final DashboardService _dashboardService;
  final BudgetAlertRepository _budgetAlertRepository;
  final TokenStorage _tokenStorage;
  final DatabaseHelper _databaseHelper;
  final BudgetSettingsStorage _budgetSettingsStorage;
  final CategoryRepository _categoryRepository;

  const DashboardRepository({
    required DashboardService dashboardService,
    required BudgetAlertRepository budgetAlertRepository,
    required TokenStorage tokenStorage,
    required DatabaseHelper databaseHelper,
    required BudgetSettingsStorage budgetSettingsStorage,
    required CategoryRepository categoryRepository,
  })  : _dashboardService = dashboardService,
        _budgetAlertRepository = budgetAlertRepository,
        _tokenStorage = tokenStorage,
        _databaseHelper = databaseHelper,
        _budgetSettingsStorage = budgetSettingsStorage,
        _categoryRepository = categoryRepository;

  Future<DashboardSummaryModel> getSummary(int userId) async {
    if (await _hasRemoteSession()) {
      try {
        final summary = await _dashboardService.getSummary();
        final dailyBudget = await _resolveDailyBudget(
          userId,
          backendDailyBudget: summary.dailyBudget,
        );
        final categories = await _loadExpenseCategories(userId);
        final backendAlerts = _budgetAlertRepository.mergeAlerts(
          summary.alerts,
          await _budgetAlertRepository.getRemoteAlerts(),
        );

        final uiTransactions =
            summary.recentTransactions.map((item) => item.toUiMap()).toList();
        final fallbackAlerts = _budgetAlertRepository.buildFallbackAlerts(
          totalIncome: summary.totalIncome,
          totalExpense: summary.totalExpense,
          transactions: uiTransactions,
          dailyBudget: dailyBudget,
          categories: categories,
        );
        final alerts = _budgetAlertRepository.mergeAlerts(
          backendAlerts,
          fallbackAlerts,
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
      } on ApiException catch (error) {
        if (!error.canUseLocalFallback) rethrow;
      }
    }

    // TODO: Remove local dashboard fallback once GET /dashboard/summary exists.
    return _localSummary(userId);
  }

  Future<DashboardSummaryModel> _localSummary(int userId) async {
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    final stats = await _databaseHelper.getMonthlyStats(userId, month);
    final transactions = await _databaseHelper.getTransactionsByMonth(
      userId,
      month,
    );

    Map<String, dynamic>? activeTarget;
    Map<String, dynamic>? targetProgress;
    try {
      activeTarget = await _databaseHelper.getActiveTarget(userId);
      if (activeTarget != null) {
        targetProgress = await _databaseHelper.getTargetProgress(
          userId,
          activeTarget['budget_id'] as int,
        );
      }
    } catch (_) {
      activeTarget = null;
      targetProgress = null;
    }

    final totalIncome = stats['income'] ?? 0;
    final totalExpense = stats['expense'] ?? 0;
    final dailyBudget = await _resolveDailyBudget(userId);
    final categories = await _loadExpenseCategories(userId);
    final alerts = await _budgetAlertRepository.getAlerts(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      transactions: transactions,
      dailyBudget: dailyBudget,
      categories: categories,
      activeTarget: activeTarget,
      targetProgress: targetProgress,
    );

    return DashboardSummaryModel(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: stats['balance'] ?? totalIncome - totalExpense,
      dailyBudget: dailyBudget,
      monthlyBudget: (activeTarget?['target_amount'] as num?)?.toDouble(),
      recentTransactions: transactions
          .take(5)
          .map((item) => TransactionModel.fromJson(item))
          .toList(),
      alerts: alerts,
    );
  }

  Future<bool> _hasRemoteSession() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<double?> _resolveDailyBudget(
    int userId, {
    double? backendDailyBudget,
  }) async {
    if (backendDailyBudget != null && backendDailyBudget > 0) {
      return backendDailyBudget;
    }

    final localBudget =
        await _budgetSettingsStorage.getDailyBudget(userId: userId);
    if (localBudget != null && localBudget > 0) return localBudget;

    return AppConfig.dailyBudget > 0 ? AppConfig.dailyBudget : null;
  }

  Future<List<Map<String, dynamic>>> _loadExpenseCategories(int userId) async {
    try {
      return _categoryRepository.getCategoriesForUi(
        type: 'expense',
        userId: userId,
      );
    } catch (_) {
      return const [];
    }
  }
}
