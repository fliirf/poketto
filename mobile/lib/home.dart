import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poketto/add_transaction.dart';
import 'package:poketto/budget_settings_page.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/data/models/budget_alert_model.dart';
import 'package:poketto/data/models/dashboard_summary_model.dart';
import 'package:poketto/data/models/exchange_rate_model.dart';
import 'package:poketto/data/models/transaction_model.dart';
import 'package:poketto/data/repositories/app_repositories.dart';
import 'package:poketto/manage_categories_page.dart';
import 'package:poketto/monthly_overview_page.dart';
import 'package:poketto/providers/user_provider.dart';
import 'package:poketto/ui/app_feedback.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/app_widgets.dart';
import 'package:poketto/ui/dashboard_sections.dart';
import 'package:poketto/ui/poketto_light_components.dart';
import 'package:poketto/ui/poketto_light_theme.dart';

enum DashboardPeriod { today, week, month, year, custom }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardSummaryModel? _summary;
  String _userName = 'User';
  DashboardPeriod _period = DashboardPeriod.month;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int? _selectedCategoryId;
  String? _selectedTransactionType;
  List<Map<String, dynamic>> _filterCategories = [];
  bool _summaryLoading = true;
  String? _summaryError;
  bool _ratesLoading = true;
  String? _ratesError;
  List<ExchangeRateModel> _rates = [];
  bool _notificationsLoading = false;
  String? _notificationsError;
  List<BudgetAlertModel> _alerts = [];
  String _preferredCurrency = 'IDR';
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadRates();
    _loadFilterCategories();
  }

  Future<void> _loadFilterCategories() async {
    try {
      final categories = await AppRepositories.categories.getCategoriesForUi();
      if (mounted) setState(() => _filterCategories = categories);
    } catch (_) {
      // Dashboard tetap dapat digunakan tanpa daftar filter kategori.
    }
  }

  Future<void> _loadDashboard({bool showLoading = true}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (mounted && showLoading) {
      setState(() {
        _summaryLoading = true;
        _summaryError = null;
      });
    }

    final user = context.read<UserProvider>();
    if (user.userId == null) {
      _refreshing = false;
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final now = DateTime.now();
    final range = _resolveDashboardRange(now);

    try {
      final results = await Future.wait<dynamic>([
        AppRepositories.dashboard.getSummary(
          user.userId!,
          month: range.month,
          startDate: range.startDate,
          endDate: range.endDate,
          type: _selectedTransactionType,
          categoryId: _selectedCategoryId,
        ),
        AppRepositories.userSettings.getSettings(userId: user.userId),
      ]);
      var summary = results[0] as DashboardSummaryModel;
      final settings = results[1] as Map<String, dynamic>;
      summary = await _withTransactionFallback(
        summary,
        month: range.month,
        startDate: range.startDate,
        endDate: range.endDate,
        type: _selectedTransactionType,
        categoryId: _selectedCategoryId,
      );

      if (!mounted) return;
      setState(() {
        _userName = user.userName ?? 'User';
        _summary = summary;
        _alerts = summary.alerts;
        _preferredCurrency =
            (readString(settings['currency']) ?? summary.currency)
                .toUpperCase();
        _summaryLoading = false;
        _summaryError = null;
      });
      await AppRepositories.notifications.showBudgetAlerts(summary.alerts);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _summaryError = error.userMessage;
        _summaryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summaryError =
            'Dashboard belum bisa dimuat. Tarik untuk mencoba lagi.';
        _summaryLoading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  DashboardDateRange _resolveDashboardRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case DashboardPeriod.today:
        return DashboardDateRange(startDate: today, endDate: today);
      case DashboardPeriod.week:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return DashboardDateRange(
          startDate: start,
          endDate: start.add(const Duration(days: 6)),
        );
      case DashboardPeriod.month:
        return DashboardDateRange(month: DateFormat('yyyy-MM').format(today));
      case DashboardPeriod.year:
        return DashboardDateRange(
          startDate: DateTime(today.year),
          endDate: DateTime(today.year, 12, 31),
        );
      case DashboardPeriod.custom:
        return DashboardDateRange(
          startDate: _customStartDate,
          endDate: _customEndDate,
        );
    }
  }

  Future<DashboardSummaryModel> _withTransactionFallback(
    DashboardSummaryModel summary, {
    String? month,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? categoryId,
  }) async {
    final missingTrend = summary.expenseTrend.isEmpty;
    final missingComposition = summary.categoryBreakdown.isEmpty;
    final missingMonthly = summary.monthlyExpense == null;
    if (!missingTrend && !missingComposition && !missingMonthly) return summary;

    try {
      final periodTransactions =
          await AppRepositories.transactions.getTransactions(
        month: month,
        startDate: startDate,
        endDate: endDate,
        type: type,
        categoryId: categoryId,
      );
      final expenses =
          periodTransactions.where((item) => item.type == 'expense').toList();
      final trend =
          missingTrend ? _buildTrend(expenses, startDate, endDate) : null;
      final composition =
          missingComposition ? _buildComposition(expenses) : null;
      double? monthlySpent;
      if (missingMonthly) {
        final activeMonth = DateFormat('yyyy-MM').format(DateTime.now());
        final monthlyTransactions = month == activeMonth
            ? periodTransactions
            : await AppRepositories.transactions.getTransactions(
                month: activeMonth,
                type: 'expense',
              );
        monthlySpent = monthlyTransactions
            .where((item) => item.type == 'expense')
            .fold<double>(0, (sum, item) => sum + item.amount);
      }
      return summary.copyWith(
        expenseTrend: trend,
        categoryBreakdown: composition,
        monthlyExpense: monthlySpent,
      );
    } catch (_) {
      return summary;
    }
  }

  List<Map<String, dynamic>> _buildComposition(
      List<TransactionModel> expenses) {
    final totals = <String, double>{};
    for (final transaction in expenses) {
      totals.update(
          transaction.categoryName, (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount);
    }
    return totals.entries
        .map((entry) => {'category': entry.key, 'total': entry.value})
        .toList();
  }

  List<Map<String, dynamic>> _buildTrend(
    List<TransactionModel> expenses,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final totals = <String, double>{};
    for (final transaction in expenses) {
      final key = DateFormat('yyyy-MM-dd').format(transaction.transactionDate);
      totals.update(key, (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount);
    }
    if (startDate == null || endDate == null) {
      return totals.entries
          .map((entry) => {'date': entry.key, 'total': entry.value})
          .toList();
    }
    final output = <Map<String, dynamic>>[];
    var cursor = DateTime(startDate.year, startDate.month, startDate.day);
    final last = DateTime(endDate.year, endDate.month, endDate.day);
    while (!cursor.isAfter(last)) {
      final key = DateFormat('yyyy-MM-dd').format(cursor);
      output.add({'date': key, 'total': totals[key] ?? 0});
      cursor = cursor.add(const Duration(days: 1));
    }
    return output;
  }

  Future<void> _loadRates() async {
    if (mounted) {
      setState(() {
        _ratesLoading = true;
        _ratesError = null;
      });
    }
    try {
      final rates =
          await AppRepositories.exchangeRates.getExchangeRates(base: 'IDR');
      if (!mounted) return;
      setState(() {
        _rates = rates.where((rate) => rate.rate > 0).toList();
        _ratesLoading = false;
        if (_rates.isEmpty) _ratesError = 'Kurs mata uang belum tersedia.';
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _ratesError = error.userMessage;
        _ratesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ratesError = 'Kurs mata uang gagal dimuat.';
        _ratesLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _notificationsLoading = true;
      _notificationsError = null;
    });
    try {
      final alerts = await AppRepositories.budgetAlerts.getRemoteAlerts();
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _notificationsLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _notificationsError = error.userMessage;
        _notificationsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notificationsError = 'Notifikasi gagal dimuat.';
        _notificationsLoading = false;
      });
    }
  }

  double get _displayRate {
    if (_preferredCurrency == 'IDR') return 1;
    for (final rate in _rates) {
      if (rate.baseCurrency == 'IDR' &&
          rate.targetCurrency == _preferredCurrency &&
          rate.rate > 0) {
        return rate.rate;
      }
    }
    return 1;
  }

  String get _displayCurrency =>
      _preferredCurrency == 'IDR' || _displayRate != 1
          ? _preferredCurrency
          : 'IDR';

  String _formatAmount(double amount) {
    final converted = amount.isFinite ? amount * _displayRate : 0.0;
    final digits =
        _displayCurrency == 'IDR' || _displayCurrency == 'JPY' ? 0 : 2;
    return NumberFormat.currency(
      locale: 'id_ID',
      name: _displayCurrency,
      symbol: '$_displayCurrency ',
      decimalDigits: digits,
    ).format(converted);
  }

  Future<void> _openAddTransaction() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    );
    if (changed == true) await _loadDashboard();
  }

  Future<void> _editTransaction(TransactionModel transaction) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionPage(transaction: transaction.toUiMap()),
      ),
    );
    if (changed == true) await _loadDashboard();
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: Text(
            'Transaksi "${transaction.description ?? transaction.categoryName}" akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: context.poketto.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AppRepositories.transactions.deleteTransaction(transaction.id);
      if (!mounted) return;
      AppFeedback.success(context, 'Transaksi berhasil dihapus.');
      await _loadDashboard();
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.userMessage);
    }
  }

  void _navigate(int index) {
    if (index == 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => switch (index) {
          1 => const MonthlyOverviewPage(),
          2 => const ManageCategoriesPage(),
          _ => const BudgetSettingsPage(),
        },
      ),
    ).then((_) => _loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    return PokettoGradientScaffold(
      bottomNavigationBar: PokettoBottomNav(
        currentIndex: 0,
        onDestinationSelected: _navigate,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([_loadDashboard(), _loadRates()]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
            children: [
              LightHeader(
                userName: _userName,
                subtitle:
                    DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now()),
                onProfileTap: _showProfileMenu,
                onNotificationsTap: _showNotificationsPanel,
                unreadNotificationsCount:
                    _alerts.where((alert) => !alert.isRead).length,
              ),
              const SizedBox(height: 16),
              _periodSelector(),
              const SizedBox(height: 16),
              if (_summaryLoading && summary == null)
                const SizedBox(
                    height: 320,
                    child: Center(child: CircularProgressIndicator()))
              else if (_summaryError != null && summary == null)
                _errorCard(_summaryError!, _loadDashboard)
              else if (summary != null) ...[
                LightBalanceCard(
                  balance: _formatAmount(summary.balance),
                  income: _formatAmount(summary.totalIncome),
                  expense: '-${_formatAmount(summary.totalExpense)}',
                  onAddPressed: _openAddTransaction,
                ),
                if (_summaryError != null) ...[
                  const SizedBox(height: 12),
                  _errorCard(_summaryError!, _loadDashboard),
                ],
                const SizedBox(height: 18),
                DashboardBudgetCard(
                  title: 'Daily budget',
                  periodLabel: DateFormat('EEEE, d MMMM', 'id_ID')
                      .format(DateTime.now()),
                  metrics: BudgetMetrics.resolve(
                    limit: summary.dailyBudget,
                    spent: summary.dailyExpense,
                    remaining: summary.dailyBudgetRemaining,
                    percentage: summary.dailyBudgetPercentage,
                    threshold: summary.budgetWarningThreshold,
                  ),
                  formatAmount: _formatAmount,
                ),
                const SizedBox(height: 14),
                DashboardBudgetCard(
                  title: 'Monthly budget',
                  periodLabel:
                      DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now()),
                  metrics: BudgetMetrics.resolve(
                    limit: summary.monthlyBudget,
                    spent: summary.monthlyExpense,
                    remaining: summary.monthlyBudgetRemaining,
                    percentage: summary.monthlyBudgetPercentage,
                    threshold: summary.budgetWarningThreshold,
                  ),
                  formatAmount: _formatAmount,
                ),
                const SizedBox(height: 18),
                ExpenseCompositionCard(
                  items: summary.categoryBreakdown,
                  formatAmount: _formatAmount,
                ),
                const SizedBox(height: 18),
                ExpenseTrendCard(
                  points: summary.expenseTrend,
                  periodLabel: summary.period?.label ?? _periodLabel,
                  formatAmount: _formatAmount,
                ),
                const SizedBox(height: 18),
                _categoryBudgetCard(summary),
                const SizedBox(height: 18),
                _recentTransactions(summary),
                const SizedBox(height: 18),
                CurrencyConverterCard(
                  rates: _rates,
                  preferredCurrency: _preferredCurrency,
                  loading: _ratesLoading,
                  error: _ratesError,
                  onRetry: _loadRates,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _periodLabel {
    final now = DateTime.now();
    return switch (_period) {
      DashboardPeriod.today => DateFormat('d MMMM yyyy', 'id_ID').format(now),
      DashboardPeriod.week => 'Minggu ini',
      DashboardPeriod.month => DateFormat('MMMM yyyy', 'id_ID').format(now),
      DashboardPeriod.year => 'Tahun ${now.year}',
      DashboardPeriod.custom => _customStartDate != null &&
              _customEndDate != null
          ? '${DateFormat('d MMM yyyy', 'id_ID').format(_customStartDate!)} - ${DateFormat('d MMM yyyy', 'id_ID').format(_customEndDate!)}'
          : 'Custom',
    };
  }

  String? get _selectedCategoryName {
    for (final category in _filterCategories) {
      if (readInt(category['category_id']) == _selectedCategoryId) {
        return readString(category['name']);
      }
    }
    return null;
  }

  int get _advancedFilterCount =>
      (_selectedCategoryId == null ? 0 : 1) +
      (_selectedTransactionType == null ? 0 : 1);

  Widget _periodSelector() => AppCard(
        key: const ValueKey('dashboard-filter-summary'),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Filter Dashboard',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(
                        [
                          _periodLabel,
                          if (_selectedCategoryName != null)
                            _selectedCategoryName!,
                          if (_selectedTransactionType != null)
                            _selectedTransactionType == 'income'
                                ? 'Pemasukan'
                                : 'Pengeluaran',
                        ].join(' • '),
                        style: TextStyle(
                            color: context.poketto.mutedText, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Badge(
                  isLabelVisible: _advancedFilterCount > 0,
                  label: Text('$_advancedFilterCount'),
                  child: IconButton.filledTonal(
                    key: const ValueKey('dashboard-filter-button'),
                    tooltip: 'Buka filter',
                    onPressed: _showAdvancedFilters,
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _periodChip(DashboardPeriod.today, 'Hari ini'),
                  _periodChip(DashboardPeriod.week, 'Minggu ini'),
                  _periodChip(DashboardPeriod.month, 'Bulan ini'),
                  _periodChip(DashboardPeriod.year, 'Tahun ini'),
                  _periodChip(DashboardPeriod.custom, 'Custom'),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _periodChip(DashboardPeriod period, String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          key: ValueKey('dashboard-period-${period.name}'),
          label: Text(label),
          selected: _period == period,
          onSelected: (_) async {
            if (period == DashboardPeriod.custom) {
              await _showAdvancedFilters(openCustomDates: true);
              return;
            }
            setState(() => _period = period);
            _loadDashboard();
          },
        ),
      );

  Future<void> _showAdvancedFilters({bool openCustomDates = false}) async {
    var draftPeriod = openCustomDates ? DashboardPeriod.custom : _period;
    var draftStart = _customStartDate;
    var draftEnd = _customEndDate;
    var draftCategoryId = _selectedCategoryId ?? 0;
    var draftType = _selectedTransactionType ?? '';

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> pickDate({required bool start}) async {
            final picked = await showDatePicker(
              context: sheetContext,
              initialDate: (start ? draftStart : draftEnd) ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked == null) return;
            setSheetState(() {
              if (start) {
                draftStart = picked;
                if (draftEnd != null && draftEnd!.isBefore(picked)) {
                  draftEnd = picked;
                }
              } else {
                draftEnd = picked;
                if (draftStart != null && draftStart!.isAfter(picked)) {
                  draftStart = picked;
                }
              }
            });
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Filter lanjutan',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    const Text('Periode',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in const [
                          (DashboardPeriod.today, 'Hari ini'),
                          (DashboardPeriod.week, 'Minggu ini'),
                          (DashboardPeriod.month, 'Bulan ini'),
                          (DashboardPeriod.year, 'Tahun ini'),
                          (DashboardPeriod.custom, 'Custom'),
                        ])
                          ChoiceChip(
                            label: Text(option.$2),
                            selected: draftPeriod == option.$1,
                            onSelected: (_) =>
                                setSheetState(() => draftPeriod = option.$1),
                          ),
                      ],
                    ),
                    if (draftPeriod == DashboardPeriod.custom) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickDate(start: true),
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(draftStart == null
                                  ? 'Tanggal mulai'
                                  : DateFormat('d MMM yyyy', 'id_ID')
                                      .format(draftStart!)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickDate(start: false),
                              icon: const Icon(Icons.event_outlined),
                              label: Text(draftEnd == null
                                  ? 'Tanggal akhir'
                                  : DateFormat('d MMM yyyy', 'id_ID')
                                      .format(draftEnd!)),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    DropdownButtonFormField<int>(
                      value: draftCategoryId,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: [
                        const DropdownMenuItem(
                            value: 0, child: Text('Semua kategori')),
                        ..._filterCategories.map(
                          (category) => DropdownMenuItem(
                            value: readInt(category['category_id']) ?? 0,
                            child: Text(
                                readString(category['name']) ?? 'Kategori'),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setSheetState(() => draftCategoryId = value ?? 0),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: draftType,
                      decoration:
                          const InputDecoration(labelText: 'Tipe transaksi'),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Semua tipe')),
                        DropdownMenuItem(
                            value: 'income', child: Text('Pemasukan')),
                        DropdownMenuItem(
                            value: 'expense', child: Text('Pengeluaran')),
                      ],
                      onChanged: (value) =>
                          setSheetState(() => draftType = value ?? ''),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const ValueKey('dashboard-filter-reset'),
                            onPressed: () {
                              setState(() {
                                _period = DashboardPeriod.month;
                                _customStartDate = null;
                                _customEndDate = null;
                                _selectedCategoryId = null;
                                _selectedTransactionType = null;
                              });
                              Navigator.pop(sheetContext, true);
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            key: const ValueKey('dashboard-filter-apply'),
                            onPressed: draftPeriod == DashboardPeriod.custom &&
                                    (draftStart == null || draftEnd == null)
                                ? null
                                : () {
                                    setState(() {
                                      _period = draftPeriod;
                                      _customStartDate = draftStart;
                                      _customEndDate = draftEnd;
                                      _selectedCategoryId = draftCategoryId == 0
                                          ? null
                                          : draftCategoryId;
                                      _selectedTransactionType =
                                          draftType.isEmpty ? null : draftType;
                                    });
                                    Navigator.pop(sheetContext, true);
                                  },
                            child: const Text('Terapkan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (applied == true) _loadDashboard();
  }

  Widget _categoryBudgetCard(DashboardSummaryModel summary) {
    final items = [...summary.categoryBudgets]..sort((a, b) =>
        (readDouble(b['percentage']) ?? 0)
            .compareTo(readDouble(a['percentage']) ?? 0));
    return AppCard(
      key: const ValueKey('category-budget-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Budget kategori',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              TextButton(
                  onPressed: () => _navigate(2), child: const Text('Kelola')),
            ],
          ),
          if (items.isEmpty)
            _emptyLabel('Budget kategori belum tersedia.')
          else
            ...items.take(5).map((item) {
              final name = readString(item['category_name'] ?? item['name']) ??
                  'Kategori';
              final spent =
                  math.max(0, readDouble(item['spent']) ?? 0).toDouble();
              final limit = math
                  .max(0, readDouble(item['monthly_budget']) ?? 0)
                  .toDouble();
              final rawPercentage = readDouble(item['percentage']) ??
                  (limit > 0 ? spent / limit * 100 : 0);
              final percentage =
                  rawPercentage.isFinite ? math.max(0, rawPercentage) : 0.0;
              final color = percentage >= 100
                  ? context.poketto.expense
                  : percentage >= summary.budgetWarningThreshold
                      ? context.poketto.warning
                      : context.poketto.income;
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800))),
                        Text('${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_formatAmount(spent)} dari ${_formatAmount(limit)}',
                            style: TextStyle(
                                color: context.poketto.mutedText, fontSize: 11),
                          ),
                        ),
                        Text(
                          percentage >= 100
                              ? 'Limit tercapai'
                              : percentage >= summary.budgetWarningThreshold
                                  ? 'Mendekati batas'
                                  : 'Aman',
                          style: TextStyle(
                              color: color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: (percentage / 100).clamp(0, 1).toDouble(),
                        color: color,
                        backgroundColor: context.poketto.softSurface,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _recentTransactions(DashboardSummaryModel summary) {
    final transactions = summary.recentTransactions.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LightSectionTitle(
          title: 'Transaksi terakhir',
          actionLabel: 'Lihat semua',
          onAction: () => _navigate(1),
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          AppCard(child: _emptyLabel('Belum ada transaksi.'))
        else
          ...transactions.map((transaction) => TransactionListItem(
                icon: _categoryIcon(transaction.categoryName),
                title: transaction.categoryName,
                subtitle: [
                  DateFormat('d MMM yyyy', 'id_ID')
                      .format(transaction.transactionDate),
                  if ((transaction.description ?? '').isNotEmpty)
                    transaction.description!,
                ].join(' • '),
                locationLabel: transaction.locationName,
                amount:
                    '${transaction.type == 'income' ? '+' : '-'}${_formatAmount(transaction.amount)}',
                isIncome: transaction.type == 'income',
                onTap: () => _editTransaction(transaction),
                onLongPress: () => _showTransactionActions(transaction),
              )),
      ],
    );
  }

  IconData _categoryIcon(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('makan')) return Icons.restaurant_rounded;
    if (normalized.contains('transport') || normalized.contains('bensin')) {
      return Icons.directions_car_rounded;
    }
    if (normalized.contains('belanja')) return Icons.shopping_bag_rounded;
    if (normalized.contains('gaji')) return Icons.payments_rounded;
    return Icons.receipt_long_rounded;
  }

  Future<void> _showTransactionActions(TransactionModel transaction) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit transaksi'),
                onTap: () {
                  Navigator.pop(context);
                  _editTransaction(transaction);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.delete_outline, color: context.poketto.expense),
                title: Text('Hapus transaksi',
                    style: TextStyle(color: context.poketto.expense)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteTransaction(transaction);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorCard(String message, VoidCallback retry) => AppCard(
        color: context.poketto.expense.withOpacity(.06),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: context.poketto.expense),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            IconButton(
                onPressed: retry, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
      );

  Widget _emptyLabel(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.poketto.mutedText)),
        ),
      );

  void _showNotificationsPanel() {
    _loadNotifications();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> refresh() async {
            await _loadNotifications();
            if (sheetContext.mounted) setSheetState(() {});
          }

          Future<void> markRead(BudgetAlertModel alert) async {
            if (alert.isRead || alert.id <= 0) return;
            final previous = _alerts;
            setState(() {
              _alerts = _alerts
                  .map((item) => item.id == alert.id
                      ? BudgetAlertModel(
                          id: item.id,
                          alertType: item.alertType,
                          message: item.message,
                          title: item.title,
                          categoryId: item.categoryId,
                          thresholdValue: item.thresholdValue,
                          currentValue: item.currentValue,
                          isRead: true,
                          createdAt: item.createdAt,
                        )
                      : item)
                  .toList();
            });
            setSheetState(() {});
            try {
              await AppRepositories.budgetAlerts.markAsRead(alert.id);
            } catch (_) {
              if (!mounted) return;
              setState(() => _alerts = previous);
              setSheetState(() {});
              AppFeedback.error(context, 'Gagal menandai notifikasi dibaca.');
            }
          }

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .72,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Notification Center',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900)),
                        ),
                        IconButton(
                            onPressed: refresh,
                            icon: const Icon(Icons.refresh_rounded)),
                      ],
                    ),
                    Text(
                      '${_alerts.where((item) => !item.isRead).length} belum dibaca',
                      style: TextStyle(
                          color: context.poketto.mutedText, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (_notificationsLoading)
                      const Expanded(
                          child: Center(child: CircularProgressIndicator()))
                    else if (_notificationsError != null)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_notificationsError!,
                                  textAlign: TextAlign.center),
                              TextButton(
                                  onPressed: refresh,
                                  child: const Text('Coba lagi')),
                            ],
                          ),
                        ),
                      )
                    else if (_alerts.isEmpty)
                      Expanded(
                        child: Center(
                          child:
                              _emptyLabel('Belum ada peringatan budget aktif.'),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: _alerts.length,
                          itemBuilder: (context, index) {
                            final alert = _alerts[index];
                            final visual = _notificationVisual(alert.alertType);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              color: alert.isRead
                                  ? Colors.transparent
                                  : visual.$2.withOpacity(.08),
                              child: ListTile(
                                onTap: () => markRead(alert),
                                leading: CircleAvatar(
                                  backgroundColor: visual.$2.withOpacity(.14),
                                  child: Icon(visual.$1, color: visual.$2),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                          alert.title ??
                                              _notificationTitle(
                                                  alert.alertType),
                                          style: TextStyle(
                                              fontWeight: alert.isRead
                                                  ? FontWeight.w700
                                                  : FontWeight.w900)),
                                    ),
                                    if (!alert.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            color: context.poketto.expense,
                                            shape: BoxShape.circle),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(alert.message),
                                    if (alert.createdAt != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        DateFormat('d MMM yyyy, HH:mm', 'id_ID')
                                            .format(alert.createdAt!.toLocal()),
                                        style: TextStyle(
                                            color: context.poketto.mutedText,
                                            fontSize: 10.5),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  (IconData, Color) _notificationVisual(String type) {
    if (type.contains('daily')) {
      return (Icons.today_rounded, context.poketto.warning);
    }
    if (type.contains('monthly')) {
      return (Icons.calendar_month_rounded, context.poketto.expense);
    }
    return (Icons.category_rounded, Theme.of(context).colorScheme.primary);
  }

  String _notificationTitle(String type) {
    if (type.contains('daily')) return 'Daily budget';
    if (type.contains('monthly')) return 'Monthly budget';
    if (type.contains('category')) return 'Budget kategori';
    return 'Peringatan budget';
  }

  void _showProfileMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final user = context.read<UserProvider>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(user.userName ?? 'User'),
                  subtitle: Text(user.userEmail ?? ''),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Pengaturan'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigate(3);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: context.poketto.expense),
                  title: Text('Logout',
                      style: TextStyle(color: context.poketto.expense)),
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await AppRepositories.auth.logout();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('userId');
    if (!mounted) return;
    context.read<UserProvider>().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }
}

class DashboardDateRange {
  final String? month;
  final DateTime? startDate;
  final DateTime? endDate;

  const DashboardDateRange({
    this.month,
    this.startDate,
    this.endDate,
  });
}
