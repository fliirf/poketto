import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/data/models/budget_alert_model.dart';
import 'package:poketto/data/models/transaction_model.dart';

class DashboardSummaryModel {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double? dailyBudget;
  final double? monthlyBudget;
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
    this.monthlyBudget,
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
      monthlyBudget:
          readDouble(json['monthly_budget'] ?? json['monthlyBudget']),
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
}
