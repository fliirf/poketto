import 'package:intl/intl.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
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
    final remoteAlerts = await getRemoteAlerts();

    // TODO: Replace fallback rules with GET /budget-alerts once backend supports it.
    final fallbackAlerts = buildFallbackAlerts(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      transactions: transactions,
      dailyBudget: dailyBudget,
      categories: categories,
      activeTarget: activeTarget,
      targetProgress: targetProgress,
    );
    return mergeAlerts(remoteAlerts, fallbackAlerts);
  }

  Future<List<BudgetAlertModel>> getRemoteAlerts() async {
    if (!await _hasRemoteSession()) return const [];

    try {
      return _budgetAlertService.getAlerts();
    } on ApiException catch (error) {
      if (!error.canUseLocalFallback) rethrow;
      return const [];
    }
  }

  List<BudgetAlertModel> buildFallbackAlerts({
    required double totalIncome,
    required double totalExpense,
    required List<Map<String, dynamic>> transactions,
    double? dailyBudget,
    List<Map<String, dynamic>> categories = const [],
    Map<String, dynamic>? activeTarget,
    Map<String, dynamic>? targetProgress,
  }) {
    final alerts = <BudgetAlertModel>[];
    final now = DateTime.now();

    if (dailyBudget != null && dailyBudget > 0) {
      final today = DateFormat('yyyy-MM-dd').format(now);
      final todayExpense = transactions.where((transaction) {
        final type = transaction['category_type']?.toString();
        final date = transaction['date']?.toString() ?? '';
        return type == 'expense' && date.startsWith(today);
      }).fold<double>(
        0,
        (sum, transaction) => sum + (readDouble(transaction['amount']) ?? 0),
      );

      if (todayExpense >= dailyBudget) {
        alerts.add(
          BudgetAlertModel(
            id: 0,
            alertType: 'daily_budget',
            message: 'Jangan belanja lagi! Budget harian sudah habis.',
            thresholdValue: dailyBudget,
            currentValue: todayExpense,
            createdAt: now,
          ),
        );
      }
    }

    alerts.addAll(
      _buildCategoryBudgetAlerts(
        transactions: transactions,
        categories: categories,
        now: now,
      ),
    );

    final progress = (targetProgress?['percentage'] as num?)?.toDouble();
    if (activeTarget != null && progress != null && progress >= 80) {
      alerts.add(
        BudgetAlertModel(
          id: 0,
          alertType: 'target_budget',
          message:
              'Peringatan! Target keuangan aktif sudah mencapai 80% dari batasnya.',
          thresholdValue:
              (activeTarget['target_amount'] as num?)?.toDouble() ?? 0,
          currentValue: (targetProgress?['spent'] as num?)?.toDouble() ?? 0,
          createdAt: now,
        ),
      );
    }

    if (totalIncome > 0 && totalExpense > totalIncome) {
      alerts.add(
        BudgetAlertModel(
          id: 0,
          alertType: 'financial_health',
          message:
              'Pengeluaran bulan ini lebih besar dari pemasukan. Cek lagi prioritas belanja Anda.',
          thresholdValue: totalIncome,
          currentValue: totalExpense,
          createdAt: now,
        ),
      );
    }

    return alerts;
  }

  List<BudgetAlertModel> _buildCategoryBudgetAlerts({
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> categories,
    required DateTime now,
  }) {
    final month = DateFormat('yyyy-MM').format(now);
    final budgetsByCategory = <int, _CategoryBudget>{};

    for (final category in categories) {
      final categoryId = readInt(category['category_id'] ?? category['id']);
      final monthlyBudget = readDouble(
        category['monthly_budget'] ??
            category['monthlyBudget'] ??
            category['budget'] ??
            category['limit'] ??
            category['budget_limit'] ??
            category['budgetLimit'],
      );

      if (categoryId == null || monthlyBudget == null || monthlyBudget <= 0) {
        continue;
      }

      budgetsByCategory[categoryId] = _CategoryBudget(
        id: categoryId,
        name: readString(category['name']) ?? 'Kategori',
        monthlyBudget: monthlyBudget,
      );
    }

    if (budgetsByCategory.isEmpty) return const [];

    final spentByCategory = <int, double>{};
    for (final transaction in transactions) {
      final type =
          readString(transaction['category_type'] ?? transaction['type']);
      final date = readString(
            transaction['date'] ?? transaction['transaction_date'],
          ) ??
          '';
      final categoryId =
          readInt(transaction['category_id'] ?? transaction['categoryId']);

      if (type != 'expense' ||
          categoryId == null ||
          !budgetsByCategory.containsKey(categoryId) ||
          !date.startsWith(month)) {
        continue;
      }

      spentByCategory[categoryId] = (spentByCategory[categoryId] ?? 0) +
          (readDouble(transaction['amount']) ?? 0);
    }

    return budgetsByCategory.values.where((category) {
      final spent = spentByCategory[category.id] ?? 0;
      return spent >= category.monthlyBudget * 0.8;
    }).map((category) {
      final spent = spentByCategory[category.id] ?? 0;
      return BudgetAlertModel(
        id: 0,
        alertType: 'category_budget_${category.id}',
        message:
            'Peringatan! Pengeluaran kategori ${category.name} telah mencapai 80% dari budget bulanan.',
        thresholdValue: category.monthlyBudget,
        currentValue: spent,
        createdAt: now,
      );
    }).toList();
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

  Future<bool> _hasRemoteSession() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}

class _CategoryBudget {
  final int id;
  final String name;
  final double monthlyBudget;

  const _CategoryBudget({
    required this.id,
    required this.name,
    required this.monthlyBudget,
  });
}
