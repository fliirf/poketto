import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:poketto/add_transaction.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/data/repositories/app_repositories.dart';
import 'package:poketto/pdf_report_generator.dart';
import 'package:poketto/providers/user_provider.dart';
import 'package:poketto/ui/app_feedback.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/app_widgets.dart';
import 'package:poketto/ui/poketto_light_theme.dart';

enum _HistoryType { all, income, expense }

enum _HistorySort { newest, oldest, highest, lowest }

class MonthlyOverviewPage extends StatefulWidget {
  const MonthlyOverviewPage({super.key});

  @override
  State<MonthlyOverviewPage> createState() => _MonthlyOverviewPageState();
}

class _MonthlyOverviewPageState extends State<MonthlyOverviewPage> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _transactions = [];
  _HistoryType _type = _HistoryType.all;
  _HistorySort _sort = _HistorySort.newest;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = context.read<UserProvider>().userId;
      if (userId == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final now = DateTime.now();
      final monthDates =
          List.generate(6, (index) => DateTime(now.year, now.month - index, 1));
      final lists = await Future.wait(monthDates.map((month) {
        return AppRepositories.transactions.getTransactionsByMonthForUi(
          userId: userId,
          month: DateFormat('yyyy-MM').format(month),
        );
      }));
      if (!mounted) return;
      setState(() {
        _transactions = lists.expand((items) => items).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Riwayat transaksi belum bisa dimuat.';
      });
    }
  }

  List<Map<String, dynamic>> get _visibleTransactions {
    final query = _searchController.text.trim().toLowerCase();
    final result = _transactions.where((tx) {
      final type = readString(tx['category_type'] ?? tx['type']) ?? 'expense';
      if (_type == _HistoryType.income && type != 'income') return false;
      if (_type == _HistoryType.expense && type != 'expense') return false;
      if (query.isEmpty) return true;
      final haystack = [
        readString(tx['category_name']),
        readString(tx['description']),
        readString(tx['location_name']),
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    result.sort((a, b) {
      final dateA =
          readDateTime(a['transaction_date'] ?? a['date']) ?? DateTime(1970);
      final dateB =
          readDateTime(b['transaction_date'] ?? b['date']) ?? DateTime(1970);
      final amountA = readDouble(a['amount']) ?? 0;
      final amountB = readDouble(b['amount']) ?? 0;
      switch (_sort) {
        case _HistorySort.oldest:
          return dateA.compareTo(dateB);
        case _HistorySort.highest:
          return amountB.compareTo(amountA);
        case _HistorySort.lowest:
          return amountA.compareTo(amountB);
        case _HistorySort.newest:
          return dateB.compareTo(dateA);
      }
    });
    return result;
  }

  Map<DateTime, List<Map<String, dynamic>>> _grouped(
      List<Map<String, dynamic>> transactions) {
    final groups = <DateTime, List<Map<String, dynamic>>>{};
    for (final tx in transactions) {
      final date =
          readDateTime(tx['transaction_date'] ?? tx['date']) ?? DateTime.now();
      final key = DateTime(date.year, date.month, date.day);
      groups.putIfAbsent(key, () => []).add(tx);
    }
    return groups;
  }

  IconData _categoryIcon(String? name) {
    final normalized = name?.toLowerCase() ?? '';
    if (normalized.contains('makan')) return Icons.restaurant_rounded;
    if (normalized.contains('transport') || normalized.contains('bensin')) {
      return Icons.directions_car_rounded;
    }
    if (normalized.contains('belanja')) return Icons.shopping_bag_rounded;
    if (normalized.contains('kesehatan'))
      return Icons.health_and_safety_rounded;
    if (normalized.contains('gaji') || normalized.contains('bonus')) {
      return Icons.payments_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  Future<void> _editTransaction(Map<String, dynamic> transaction) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionPage(transaction: transaction),
      ),
    );
    if (changed == true) _loadTransactions();
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text('Data transaksi akan dihapus dari web dan mobile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
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
      final id = readInt(transaction['transaction_id'] ?? transaction['id']);
      if (id == null) throw const FormatException();
      await AppRepositories.transactions.deleteTransaction(id);
      if (!mounted) return;
      AppFeedback.success(context, 'Transaksi berhasil dihapus.');
      _loadTransactions();
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.userMessage);
    } catch (_) {
      if (mounted) AppFeedback.error(context, 'Transaksi gagal dihapus.');
    }
  }

  Future<void> _showTransactionActions(Map<String, dynamic> transaction) async {
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

  Future<void> _exportPdf() async {
    final transactions = _visibleTransactions;
    if (transactions.isEmpty) {
      AppFeedback.info(context, 'Tidak ada transaksi untuk diekspor.');
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final file = await PdfReportGenerator.generateMonthlyReport(
        month: DateTime.now(),
        transactions: transactions,
      );
      if (!mounted) return;
      Navigator.pop(context);
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done && mounted) {
        AppFeedback.error(context, 'PDF tidak dapat dibuka.');
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      AppFeedback.error(context, 'Laporan PDF gagal dibuat.');
    }
  }

  String _dateHeading(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date == today)
      return 'HARI INI, ${DateFormat('d MMM', 'id_ID').format(date)}';
    if (date == today.subtract(const Duration(days: 1))) {
      return 'KEMARIN, ${DateFormat('d MMM', 'id_ID').format(date)}';
    }
    return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date).toUpperCase();
  }

  void _navigate(int index) {
    if (index == 1) return;
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    Navigator.pushReplacementNamed(
        context, index == 2 ? '/categories' : '/settings');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.poketto;
    final visible = _visibleTransactions;
    final groups = _grouped(visible);

    return PokettoGradientScaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Ekspor PDF',
            onPressed: _isLoading ? null : _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: PokettoBottomNav(
        currentIndex: 1,
        onDestinationSelected: _navigate,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadTransactions,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Cari transaksi...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: _showFilters,
                    icon: const Icon(Icons.filter_list_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  PopupMenuButton<_HistorySort>(
                    initialValue: _sort,
                    onSelected: (value) => setState(() => _sort = value),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: _HistorySort.newest, child: Text('Terbaru')),
                      PopupMenuItem(
                          value: _HistorySort.oldest, child: Text('Terlama')),
                      PopupMenuItem(
                          value: _HistorySort.highest,
                          child: Text('Nominal terbesar')),
                      PopupMenuItem(
                          value: _HistorySort.lowest,
                          child: Text('Nominal terkecil')),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Urutkan: ',
                            style: TextStyle(color: semantic.mutedText)),
                        Text(_sortLabel,
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800)),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'TOTAL: ${visible.length} ITEM',
                    style: TextStyle(
                      color: semantic.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _stateCard(Icons.error_outline_rounded, _error!)
              else if (visible.isEmpty)
                _stateCard(
                    Icons.search_off_rounded, 'Tidak ada transaksi yang cocok.')
              else
                ...groups.entries.map((entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 18, 4, 12),
                          child: Text(
                            _dateHeading(entry.key),
                            style: TextStyle(
                              color: semantic.mutedText,
                              fontSize: 12,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        ...entry.value.map((tx) {
                          final type =
                              readString(tx['category_type'] ?? tx['type']);
                          final isIncome = type == 'income';
                          final date = readDateTime(
                                  tx['transaction_date'] ?? tx['date']) ??
                              entry.key;
                          final description =
                              readString(tx['description']) ?? '';
                          return TransactionListItem(
                            icon:
                                _categoryIcon(readString(tx['category_name'])),
                            title:
                                readString(tx['category_name']) ?? 'Transaksi',
                            subtitle: description.isEmpty
                                ? (isIncome ? 'Pemasukan' : 'Pengeluaran')
                                : description,
                            locationLabel: readString(tx['location_name']),
                            timeLabel: DateFormat('HH:mm').format(date),
                            amount:
                                '${isIncome ? '+' : '-'}${_formatCurrency(readDouble(tx['amount']) ?? 0)}',
                            isIncome: isIncome,
                            onTap: () => _editTransaction(tx),
                            onLongPress: () => _showTransactionActions(tx),
                          );
                        }),
                      ],
                    )),
            ],
          ),
        ),
      ),
    );
  }

  String get _sortLabel => switch (_sort) {
        _HistorySort.newest => 'Terbaru',
        _HistorySort.oldest => 'Terlama',
        _HistorySort.highest => 'Terbesar',
        _HistorySort.lowest => 'Terkecil',
      };

  Widget _stateCard(IconData icon, String message) => AppCard(
        margin: const EdgeInsets.only(top: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(
            children: [
              Icon(icon, size: 46, color: context.poketto.mutedText),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Future<void> _showFilters() async {
    final selected = await showModalBottomSheet<_HistoryType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter transaksi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              RadioListTile(
                value: _HistoryType.all,
                groupValue: _type,
                title: const Text('Semua'),
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile(
                value: _HistoryType.income,
                groupValue: _type,
                title: const Text('Pemasukan'),
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile(
                value: _HistoryType.expense,
                groupValue: _type,
                title: const Text('Pengeluaran'),
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) setState(() => _type = selected);
  }
}
