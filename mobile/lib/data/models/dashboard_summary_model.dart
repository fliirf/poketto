import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/data/models/budget_alert_model.dart';
import 'package:poketto/data/models/transaction_model.dart';

class DashboardSummaryModel {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double? dailyBudget;
  final double? dailyExpense;
  final double? dailyBudgetRemaining;
  final double? dailyBudgetPercentage;
  final double? monthlyBudget;
  final double? monthlyExpense;
  final double? monthlyBudgetRemaining;
  final double? monthlyBudgetPercentage;
  final String currency;
  final double budgetWarningThreshold;
  final DashboardPeriodModel? period;
  final List<Map<String, dynamic>> expenseTrend;
  final List<Map<String, dynamic>> categoryBreakdown;
  final List<Map<String, dynamic>> categoryBudgets;
  final List<TransactionModel> recentTransactions;
  final List<BudgetAlertModel> alerts;

  const DashboardSummaryModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    this.dailyBudget,
    this.dailyExpense,
    this.dailyBudgetRemaining,
    this.dailyBudgetPercentage,
    this.monthlyBudget,
    this.monthlyExpense,
    this.monthlyBudgetRemaining,
    this.monthlyBudgetPercentage,
    this.currency = 'IDR',
    this.budgetWarningThreshold = 80,
    this.period,
    this.expenseTrend = const [],
    this.categoryBreakdown = const [],
    this.categoryBudgets = const [],
    this.recentTransactions = const [],
    this.alerts = const [],
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final recentRaw = readListPayload(
      json,
      const ['recent_transactions', 'recentTransactions', 'transactions'],
    );
    final alertRaw = readListPayload(json, const ['alerts', 'budget_alerts']);
    final trendRaw =
        readListPayload(json, const ['expense_trend', 'expenseTrend']);
    final breakdownRaw = readListPayload(
        json, const ['category_breakdown', 'categoryBreakdown']);
    final categoryBudgetRaw =
        readListPayload(json, const ['category_budgets', 'categoryBudgets']);
    final settings = asStringDynamicMap(
      json['settings'] ?? json['user_settings'] ?? json['userSettings'],
    );

    final income = readDouble(json['total_income'] ?? json['totalIncome']) ?? 0;
    final expense =
        readDouble(json['total_expense'] ?? json['totalExpense']) ?? 0;

    return DashboardSummaryModel(
      totalIncome: income,
      totalExpense: expense,
      balance: readDouble(json['balance'] ?? json['saldo']) ?? income - expense,
      dailyBudget: readDouble(
        json['daily_budget'] ??
            json['dailyBudget'] ??
            settings['daily_budget'] ??
            settings['dailyBudget'],
      ),
      dailyExpense: readDouble(json['daily_expense'] ?? json['dailyExpense']),
      dailyBudgetRemaining: readDouble(
          json['daily_budget_remaining'] ?? json['dailyBudgetRemaining']),
      dailyBudgetPercentage: readDouble(
          json['daily_budget_percentage'] ?? json['dailyBudgetPercentage']),
      monthlyBudget: readDouble(json['monthly_budget'] ??
          json['monthlyBudget'] ??
          settings['monthly_budget'] ??
          settings['monthlyBudget']),
      monthlyExpense:
          readDouble(json['monthly_expense'] ?? json['monthlyExpense']),
      monthlyBudgetRemaining: readDouble(
          json['monthly_budget_remaining'] ?? json['monthlyBudgetRemaining']),
      monthlyBudgetPercentage: readDouble(
          json['monthly_budget_percentage'] ?? json['monthlyBudgetPercentage']),
      currency: (readString(json['currency'] ?? settings['currency']) ?? 'IDR')
          .toUpperCase(),
      budgetWarningThreshold: (readDouble(json['budget_warning_threshold'] ??
                  json['budgetWarningThreshold'] ??
                  settings['budget_warning_threshold']) ??
              80)
          .clamp(1, 100)
          .toDouble(),
      period: DashboardPeriodModel.tryParse(json['period']),
      expenseTrend: trendRaw.map((item) => asStringDynamicMap(item)).toList(),
      categoryBreakdown:
          breakdownRaw.map((item) => asStringDynamicMap(item)).toList(),
      categoryBudgets:
          categoryBudgetRaw.map((item) => asStringDynamicMap(item)).toList(),
      recentTransactions: recentRaw
          .map((item) => TransactionModel.fromJson(asStringDynamicMap(item)))
          .toList(),
      alerts: alertRaw
          .map((item) => BudgetAlertModel.fromJson(asStringDynamicMap(item)))
          .toList(),
    );
  }

  DashboardSummaryModel copyWith({
    double? totalIncome,
    double? totalExpense,
    double? balance,
    double? dailyBudget,
    double? dailyExpense,
    double? dailyBudgetRemaining,
    double? dailyBudgetPercentage,
    double? monthlyBudget,
    double? monthlyExpense,
    double? monthlyBudgetRemaining,
    double? monthlyBudgetPercentage,
    String? currency,
    double? budgetWarningThreshold,
    DashboardPeriodModel? period,
    List<Map<String, dynamic>>? expenseTrend,
    List<Map<String, dynamic>>? categoryBreakdown,
    List<Map<String, dynamic>>? categoryBudgets,
    List<TransactionModel>? recentTransactions,
    List<BudgetAlertModel>? alerts,
  }) {
    return DashboardSummaryModel(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      dailyBudget: dailyBudget ?? this.dailyBudget,
      dailyExpense: dailyExpense ?? this.dailyExpense,
      dailyBudgetRemaining: dailyBudgetRemaining ?? this.dailyBudgetRemaining,
      dailyBudgetPercentage:
          dailyBudgetPercentage ?? this.dailyBudgetPercentage,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
      monthlyBudgetRemaining:
          monthlyBudgetRemaining ?? this.monthlyBudgetRemaining,
      monthlyBudgetPercentage:
          monthlyBudgetPercentage ?? this.monthlyBudgetPercentage,
      currency: currency ?? this.currency,
      budgetWarningThreshold:
          budgetWarningThreshold ?? this.budgetWarningThreshold,
      period: period ?? this.period,
      expenseTrend: expenseTrend ?? this.expenseTrend,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      alerts: alerts ?? this.alerts,
    );
  }
}

class DashboardPeriodModel {
  final DateTime? startDate;
  final DateTime? endDate;
  final String label;

  const DashboardPeriodModel({
    this.startDate,
    this.endDate,
    required this.label,
  });

  static DashboardPeriodModel? tryParse(dynamic value) {
    final map = asStringDynamicMap(value);
    if (map.isEmpty) return null;
    return DashboardPeriodModel(
      startDate: readDateTime(map['start_date'] ?? map['startDate']),
      endDate: readDateTime(map['end_date'] ?? map['endDate']),
      label: readString(map['label']) ?? 'Periode terpilih',
    );
  }
}
