import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poketto/data/models/dashboard_summary_model.dart';
import 'package:poketto/data/models/exchange_rate_model.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/dashboard_sections.dart';

void main() {
  group('Dashboard contract parsing', () {
    test('parses numeric strings, nulls, period, and budget metrics safely',
        () {
      final summary = DashboardSummaryModel.fromJson({
        'total_income': '100000',
        'total_expense': 25000,
        'balance': '75000',
        'daily_budget': '50000',
        'daily_expense': '10000',
        'daily_budget_remaining': '40000',
        'daily_budget_percentage': '20',
        'monthly_budget': 500000,
        'monthly_expense': '25000',
        'monthly_budget_remaining': 475000,
        'monthly_budget_percentage': '5',
        'currency': 'usd',
        'budget_warning_threshold': '80',
        'period': {
          'start_date': '2026-06-01',
          'end_date': '2026-06-30',
          'label': 'Juni 2026',
        },
        'expense_trend': [],
        'category_breakdown': [],
        'category_budgets': [],
        'recent_transactions': [],
        'alerts': [],
      });

      expect(summary.totalIncome, 100000);
      expect(summary.dailyExpense, 10000);
      expect(summary.monthlyExpense, 25000);
      expect(summary.currency, 'USD');
      expect(summary.period?.label, 'Juni 2026');
    });

    test('rejects NaN and infinity', () {
      final summary = DashboardSummaryModel.fromJson({
        'total_income': 'NaN',
        'total_expense': 'Infinity',
        'balance': null,
      });

      expect(summary.totalIncome, 0);
      expect(summary.totalExpense, 0);
      expect(summary.balance, 0);
    });
  });

  group('Budget metrics', () {
    test('zero budget stays finite and unset', () {
      final metrics = BudgetMetrics.resolve(
        limit: 0,
        spent: 100,
        percentage: double.infinity,
      );

      expect(metrics.progress, 0);
      expect(metrics.health, BudgetHealth.unset);
      expect(metrics.percentage.isFinite, isTrue);
    });

    test('detects warning and exceeded states', () {
      expect(
        BudgetMetrics.resolve(limit: 100, spent: 80, threshold: 80).health,
        BudgetHealth.warning,
      );
      expect(
        BudgetMetrics.resolve(limit: 100, spent: 101, threshold: 80).health,
        BudgetHealth.exceeded,
      );
    });
  });

  group('Exchange-rate semantics', () {
    const rates = [
      ExchangeRateModel(
        baseCurrency: 'IDR',
        targetCurrency: 'USD',
        rate: 0.000061,
      ),
      ExchangeRateModel(
        baseCurrency: 'IDR',
        targetCurrency: 'EUR',
        rate: 0.000052,
      ),
    ];

    test('IDR to USD follows backend fixture semantics', () {
      final result = CurrencyConverter.convert(
        amount: 1000000,
        baseCurrency: 'IDR',
        targetCurrency: 'USD',
        rates: rates,
      );
      expect(result, closeTo(61, 0.000001));
    });

    test('USD to IDR reverses the same rate exactly once', () {
      final result = CurrencyConverter.convert(
        amount: 1,
        baseCurrency: 'USD',
        targetCurrency: 'IDR',
        rates: rates,
      );
      expect(result, closeTo(1 / 0.000061, 0.000001));
    });

    test('cross conversion uses targetRate divided by baseRate', () {
      final result = CurrencyConverter.convert(
        amount: 10,
        baseCurrency: 'USD',
        targetCurrency: 'EUR',
        rates: rates,
      );
      expect(result, closeTo(10 * 0.000052 / 0.000061, 0.000001));
    });
  });

  group('Dashboard widgets', () {
    testWidgets('budget, empty donut, and zero trend render without crashing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ListView(
              children: [
                DashboardBudgetCard(
                  title: 'Monthly budget',
                  periodLabel: 'Juni 2026',
                  metrics: BudgetMetrics.resolve(limit: 0, spent: 0),
                  formatAmount: (value) => 'IDR ${value.toStringAsFixed(0)}',
                ),
                ExpenseCompositionCard(
                  items: const [],
                  formatAmount: (value) => 'IDR ${value.toStringAsFixed(0)}',
                ),
                ExpenseTrendCard(
                  points: const [
                    {'date': '2026-06-01', 'total': 0},
                  ],
                  periodLabel: 'Juni 2026',
                  formatAmount: (value) => 'IDR ${value.toStringAsFixed(0)}',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Monthly budget'), findsOneWidget);
      expect(find.text('Belum ada pengeluaran pada periode ini.'),
          findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('donut and converter render populated data and swap',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ListView(
              children: [
                ExpenseCompositionCard(
                  items: const [
                    {'category': 'Makan', 'total': '75000'},
                    {'category': 'Transport', 'total': 25000},
                  ],
                  formatAmount: (value) => 'IDR ${value.toStringAsFixed(0)}',
                ),
                const CurrencyConverterCard(
                  rates: [
                    ExchangeRateModel(
                      baseCurrency: 'IDR',
                      targetCurrency: 'USD',
                      rate: 0.000061,
                    ),
                  ],
                  preferredCurrency: 'USD',
                  loading: false,
                  error: null,
                  onRetry: _noop,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('expense-donut-chart')), findsOneWidget);
      expect(find.text('Makan'), findsOneWidget);
      expect(find.textContaining('16.393'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('converter-swap')));
      await tester.pump();

      expect(find.textContaining('0,000061 USD'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}

void _noop() {}
