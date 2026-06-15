import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poketto/add_transaction.dart';
import 'package:poketto/budget_settings_page.dart';
import 'package:poketto/category_budgets_page.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/data/models/budget_alert_model.dart';
import 'package:poketto/data/repositories/app_repositories.dart';
import 'package:poketto/database/database_helper.dart';
import 'package:poketto/providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:poketto/monthly_overview_page.dart';
import 'package:poketto/folder_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poketto/all_categories_page.dart';
import 'package:poketto/target_page.dart';
import 'package:poketto/manage_categories_page.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/app_widgets.dart';
import 'package:poketto/ui/poketto_light_components.dart';
import 'package:poketto/ui/poketto_light_theme.dart';

Map<String, dynamic>? activeTarget;
Map<String, dynamic>? targetProgress;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OverlayEntry? _overlayEntry;

  String userName = 'User';
  double saldo = 0.0;
  double pemasukan = 0.0;
  double pengeluaran = 0.0;
  double? _dailyBudget;
  final PageController _budgetPageController = PageController();
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  String? _loadError;
  List<BudgetAlertModel> _alerts = [];
  List<Map<String, dynamic>> _folders = [];
  List<Map<String, dynamic>> _expenseCategories = [];
  Map<int, Map<String, dynamic>> _categoryBudgetProgress = {};
  int _budgetPageIndex = 0;
  int? _selectedBudgetCategoryId;
  bool _isLoadingData = false;
  bool _hasLoadedOnce = false;

  bool _isSelectionMode = false;
  final Set<int> _selectedTransactions = <int>{};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _budgetPageController.dispose();
    super.dispose();
  }

  void _enterSelectionMode() {
    hidePopupMenu();
    setState(() {
      _isSelectionMode = true;
      _selectedTransactions.clear();
    });
  }

  // FIXED: Added missing _exitSelectionMode method
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTransactions.clear();
    });
  }

  void _showTransactionOptions(
      BuildContext context, Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE5E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kelola Transaksi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Anda yakin ingin mengelola transaksi ini?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTransactionPage(
                            transaction: transaction,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadData();
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context, transaction);
                    },
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE5E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Hapus Transaksi?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Anda yakin ingin menghapus ${transaction['description'] ?? 'transaksi ini'}?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _deleteTransaction(
                              transaction['transaction_id'] as int);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // FIXED: Proper transaction deletion with folder cleanup
  Future<void> _deleteTransaction(int transactionId) async {
    try {
      final db = DatabaseHelper.instance;

      // FIXED: Hapus dari folder_transaction terlebih dahulu
      await db.database.then((database) async {
        await database.delete(
          'folder_transaction',
          where: 'transaction_id = ?',
          whereArgs: [transactionId],
        );
      });

      // Hapus transaksi dari API jika tersedia, lalu fallback lokal jika perlu.
      final result = await AppRepositories.transactions.deleteTransaction(
        transactionId,
      );

      // FIXED: Bersihkan folder yang kosong
      await db.deleteEmptyFolders();

      if (!mounted) return;

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Transaksi berhasil dihapus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      } else {
        throw Exception('Gagal menghapus transaksi');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.userMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showCreateFolderDialog() async {
    final folderNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buat Kategori Baru'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: folderNameController,
              decoration:
                  const InputDecoration(hintText: "Contoh: Liburan Bali"),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kategori tidak boleh kosong';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Buat'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final userProvider =
                      Provider.of<UserProvider>(context, listen: false);
                  final db = DatabaseHelper.instance;
                  final folderName = folderNameController.text.trim();
                  final transactionIds = _selectedTransactions.toList();

                  await db.createFolder(
                      userProvider.userId!, folderName, transactionIds);

                  if (!mounted) return;

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Kategori "$folderName" berhasil dibuat')),
                  );

                  _exitSelectionMode();
                  _loadData();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddToFolderDialog() async {
    if (_folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Tidak ada kategori. Buat kategori baru terlebih dahulu.')),
      );
      return;
    }

    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Tambahkan ke Kategori',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _folders.length,
                itemBuilder: (context, index) {
                  final folder = _folders[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined,
                        color: AppColors.primary),
                    title: Text(folder['name']),
                    subtitle: Text('${folder['transaction_count']} items'),
                    onTap: () async {
                      final db = DatabaseHelper.instance;
                      final folderId = folder['folder_id'] as int;
                      final transactionIds = _selectedTransactions.toList();

                      await db.addTransactionsToFolder(
                          folderId, transactionIds);

                      if (!mounted) return;

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Berhasil menambahkan ke kategori "${folder['name']}"')),
                      );

                      _exitSelectionMode();
                      _loadData();
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadData({bool forceLoading = false}) async {
    if (_isLoadingData) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    _isLoadingData = true;
    if (mounted && (!_hasLoadedOnce || forceLoading)) {
      setState(() => isLoading = true);
    }

    try {
      final db = DatabaseHelper.instance;
      final user = await db.getUserById(userId);
      if (user != null) {
        userName = user['name'] as String;
      } else {
        userName = userProvider.userName ?? 'User';
      }
      final now = DateTime.now();
      final currentMonth = DateFormat('yyyy-MM').format(now);
      final results = await Future.wait<dynamic>([
        AppRepositories.dashboard.getSummary(userId),
        AppRepositories.transactions.getTransactionsByMonthForUi(
          userId: userId,
          month: currentMonth,
        ),
        db.getFoldersByUser(userId),
        AppRepositories.categories.getCategoriesForUi(
          type: 'expense',
          userId: userId,
        ),
        AppRepositories.userSettings.getBudgetWarningThreshold(
          userId: userId,
        ),
      ]);
      final summary = results[0];
      final txList = results[1] as List<Map<String, dynamic>>;
      final folderList = results[2] as List<Map<String, dynamic>>;
      final expenseCategories = results[3] as List<Map<String, dynamic>>;
      final warningThreshold = results[4] as double;
      final fallbackAlerts = AppRepositories.budgetAlerts.buildFallbackAlerts(
        totalIncome: summary.totalIncome,
        totalExpense: summary.totalExpense,
        transactions: txList,
        dailyBudget: summary.dailyBudget,
        categories: expenseCategories,
      );
      final alerts = AppRepositories.budgetAlerts.mergeAlerts(
        summary.alerts,
        fallbackAlerts,
      );

      // FIXED: Added error handling for target loading
      Map<String, dynamic>? target;
      Map<String, dynamic>? progress;

      try {
        target = await db.getActiveTarget(userId);
        if (target != null) {
          progress = _calculateTargetProgress(target, txList);
        }
      } catch (e) {
        print('Error loading target: $e');
        target = null;
        progress = null;
      }

      if (!mounted) return;

      setState(() {
        saldo = summary.balance;
        pemasukan = summary.totalIncome;
        pengeluaran = summary.totalExpense;
        _dailyBudget = summary.dailyBudget;
        transactions = txList;
        _alerts = alerts;
        _folders = folderList;
        _expenseCategories = expenseCategories;
        _categoryBudgetProgress = _calculateCategoryBudgetProgress(
          expenseCategories,
          txList,
        );
        if (_selectedBudgetCategoryId == null ||
            !_expenseCategories.any((category) =>
                readInt(category['category_id']) ==
                _selectedBudgetCategoryId)) {
          _selectedBudgetCategoryId = _expenseCategories.isEmpty
              ? null
              : readInt(_expenseCategories.first['category_id']);
        }
        activeTarget = target;
        targetProgress = progress;
        _loadError = null;
        isLoading = false;
        _hasLoadedOnce = true;
      });
      await AppRepositories.notifications.checkBudgetUsage(
        userId: userId,
        warningThreshold: warningThreshold,
        transactions: txList,
        categories: expenseCategories,
        dailyLimit: summary.dailyBudget,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.userMessage;
        isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (!mounted) return;
      setState(() {
        _loadError = 'Data belum bisa dimuat. Coba refresh.';
        isLoading = false;
        _hasLoadedOnce = true;
      });
    } finally {
      _isLoadingData = false;
    }
  }

  String _formatBudgetInput(double? amount) {
    if (amount == null || amount <= 0) return '';
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp. ${formatter.format(amount.toInt()).replaceAll(',', '.')}';
  }

  Map<String, dynamic>? _selectedBudgetCategory() {
    if (_selectedBudgetCategoryId == null) return null;
    for (final category in _expenseCategories) {
      if (readInt(category['category_id']) == _selectedBudgetCategoryId) {
        return category;
      }
    }
    return null;
  }

  Map<int, Map<String, dynamic>> _calculateCategoryBudgetProgress(
    List<Map<String, dynamic>> categories,
    List<Map<String, dynamic>> txList,
  ) {
    final spentByCategory = <int, double>{};

    for (final tx in txList) {
      final type = readString(tx['category_type'] ?? tx['type']);
      if (type != 'expense') continue;

      final categoryId = readInt(tx['category_id'] ?? tx['categoryId']);
      final amount = readDouble(tx['amount']) ?? 0;
      if (categoryId == null) continue;

      spentByCategory[categoryId] = (spentByCategory[categoryId] ?? 0) + amount;
    }

    return {
      for (final category in categories)
        if (readInt(category['category_id'] ?? category['id']) != null)
          readInt(category['category_id'] ?? category['id'])!: () {
            final categoryId =
                readInt(category['category_id'] ?? category['id'])!;
            final budget = readDouble(category['monthly_budget']) ?? 0;
            final spent = spentByCategory[categoryId] ?? 0;
            final percentage = budget > 0 ? (spent / budget * 100) : 0.0;

            return {
              'spent': spent,
              'budget': budget,
              'remaining': budget - spent > 0 ? budget - spent : 0.0,
              'percentage': percentage.clamp(0.0, 100.0),
              'progress': budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0,
            };
          }(),
    };
  }

  Map<String, dynamic> _calculateTargetProgress(
    Map<String, dynamic> target,
    List<Map<String, dynamic>> txList,
  ) {
    final budgetId = readInt(target['budget_id'] ?? target['id']);
    final categoryId = readInt(target['category_id'] ?? target['categoryId']);
    final categoryName =
        readString(target['category_name'] ?? target['categoryName']);
    final targetAmount = readDouble(
          target['target_amount'] ??
              target['targetAmount'] ??
              target['monthly_budget'] ??
              target['monthlyBudget'],
        ) ??
        0;
    final startDate = readDateTime(target['start_date'] ?? target['startDate']);
    final endDate = readDateTime(target['end_date'] ?? target['endDate']);

    double spent = 0;
    for (final tx in txList) {
      final type = readString(tx['category_type'] ?? tx['type']);
      if (type != 'expense') continue;

      final txBudgetId = readInt(tx['budget_id'] ?? tx['budgetId']);
      final txCategoryId = readInt(tx['category_id'] ?? tx['categoryId']);
      final txCategoryName =
          readString(tx['category_name'] ?? tx['categoryName']);
      final matchesBudget = budgetId != null && txBudgetId == budgetId;
      final matchesCategory = categoryId != null && txCategoryId == categoryId;
      final matchesCategoryName = categoryName != null &&
          txCategoryName != null &&
          categoryName.toLowerCase() == txCategoryName.toLowerCase();
      if (!matchesBudget && !matchesCategory && !matchesCategoryName) continue;

      final txDate = readDateTime(tx['transaction_date'] ?? tx['date']);
      if (txDate != null) {
        if (startDate != null && txDate.isBefore(startDate)) continue;
        if (endDate != null &&
            txDate.isAfter(
              DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
            )) {
          continue;
        }
      }

      spent += readDouble(tx['amount']) ?? 0;
    }

    final remaining = targetAmount - spent;
    final percentage = targetAmount > 0 ? (spent / targetAmount * 100) : 0.0;

    return {
      'spent': spent,
      'target': targetAmount,
      'remaining': remaining > 0 ? remaining : 0.0,
      'percentage': percentage.clamp(0.0, 100.0),
    };
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  IconData getCategoryIcon(String? categoryName) {
    if (categoryName == null) return Icons.help_outline;
    switch (categoryName.toLowerCase()) {
      case 'gaji':
      case 'bonus':
        return Icons.attach_money_rounded;
      case 'makanan':
        return Icons.restaurant_outlined;
      case 'transport':
      case 'bensin':
        return Icons.directions_car_outlined;
      case 'hiburan':
        return Icons.movie_outlined;
      case 'belanja':
        return Icons.shopping_bag_outlined;
      case 'tagihan':
        return Icons.receipt_long_outlined;
      default:
        return Icons.attach_money_rounded;
    }
  }

  void showPopupMenu() {
    hidePopupMenu();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 110,
        left: MediaQuery.of(context).size.width / 2 - 110,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 220,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    hidePopupMenu();
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddTransactionPage()),
                    );
                    if (result == true) _loadData();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.add, color: Colors.black),
                        SizedBox(width: 10),
                        Text("Tambah Transaksi",
                            style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: Colors.black12),
                InkWell(
                  onTap: () async {
                    hidePopupMenu();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageCategoriesPage(
                          initialAddType: 'expense',
                        ),
                      ),
                    );
                    _loadData();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.black),
                        SizedBox(width: 10),
                        Text("Tambah Kategori", style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: Colors.black12),
                InkWell(
                  onTap: () async {
                    hidePopupMenu();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ManageCategoriesPage()),
                    );
                    _loadData();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.category_outlined, color: Colors.black),
                        SizedBox(width: 10),
                        Text("Kelola Kategori", style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void hidePopupMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isSelectionMode) {
      return Scaffold(
        backgroundColor: PokettoLightColors.backgroundMid,
        bottomNavigationBar: _buildSelectionBottomBar(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildSelectionList(),
      );
    }

    return PokettoGradientScaffold(
      bottomNavigationBar: LightBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            hidePopupMenu();
            return;
          }
          if (index == 1) {
            if (_overlayEntry == null) {
              showPopupMenu();
            } else {
              hidePopupMenu();
            }
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MonthlyOverviewPage()),
          );
        },
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildNormalContent(),
    );
  }

  Widget _buildSelectionBottomBar() {
    return BottomAppBar(
      elevation: 8,
      child: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _exitSelectionMode,
              child: const Text('Batal', style: TextStyle(fontSize: 16)),
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _selectedTransactions.isEmpty
                      ? null
                      : _showAddToFolderDialog,
                  child: const Text('Add'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _selectedTransactions.isEmpty
                      ? null
                      : _showCreateFolderDialog,
                  child: const Text('New'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            'Pilih Transaksi (${_selectedTransactions.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: transactions.isEmpty
              ? const Center(child: Text('Tidak ada transaksi untuk dipilih.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isSelected =
                        _selectedTransactions.contains(tx['transaction_id']);
                    return Card(
                      elevation: isSelected ? 3 : 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isSelected
                            ? const BorderSide(
                                color: AppColors.primary, width: 1.5)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTransactions
                                  .remove(tx['transaction_id']);
                            } else {
                              _selectedTransactions
                                  .add(tx['transaction_id'] as int);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _transaksiItem(
                            icon: getCategoryIcon(tx['category_name']),
                            title: tx['category_name'] ?? 'Unknown',
                            tanggal: _formatDate(tx['date']),
                            nominal: (tx['category_type'] == 'income')
                                ? formatCurrency(
                                    (tx['amount'] as num).toDouble())
                                : "-${formatCurrency((tx['amount'] as num).toDouble())}",
                            isPositive: tx['category_type'] == 'income',
                            description: tx['description'] ?? '',
                            locationLabel: _formatTransactionLocation(tx),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNormalContent() {
    final currentMonth =
        DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());
    final recent = transactions.take(5).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: PokettoLightColors.primary,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              LightHeader(
                userName: userName,
                subtitle: currentMonth,
                onProfileTap: () => _showProfileMenu(context),
              ),
              const SizedBox(height: 22),
              LightBalanceCard(
                balance: formatCurrency(saldo),
                income: formatCurrency(pemasukan),
                expense: '-${formatCurrency(pengeluaran)}',
              ),
              const SizedBox(height: 22),
              _buildLightShortcuts(),
              const SizedBox(height: 22),
              if (_loadError != null)
                _buildLightMessageCard(_loadError!, Icons.error_outline_rounded,
                    PokettoLightColors.red),
              if (_alerts.isNotEmpty) ...[
                ..._alerts.take(2).map((alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildLightMessageCard(
                          alert.message,
                          Icons.warning_amber_rounded,
                          PokettoLightColors.primary),
                    )),
                const SizedBox(height: 4),
              ],
              _buildLightBudgetSummary(),
              const SizedBox(height: 22),
              LightSectionTitle(
                title: 'Transaksi terbaru',
                actionLabel: 'Lihat semua',
                onAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MonthlyOverviewPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (recent.isEmpty)
                _buildLightEmptyTransactions()
              else
                ...recent.map((tx) {
                  final isIncome = tx['category_type'] == 'income';
                  final description = readString(tx['description']) ?? '';
                  final subtitle = [
                    _formatDate(readString(tx['date'])),
                    if (description.isNotEmpty) description,
                  ].join(' - ');

                  return LightTransactionItem(
                    icon: getCategoryIcon(readString(tx['category_name'])),
                    title: readString(tx['category_name']) ?? 'Unknown',
                    subtitle: subtitle,
                    amount: isIncome
                        ? formatCurrency(readDouble(tx['amount']) ?? 0)
                        : '-${formatCurrency(readDouble(tx['amount']) ?? 0)}',
                    isIncome: isIncome,
                    onLongPress: () => _showTransactionOptions(context, tx),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLightShortcuts() {
    return Row(
      children: [
        Expanded(
          child: LightFeatureShortcut(
            icon: Icons.add_rounded,
            label: 'Tambah',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionPage()),
              );
              if (result == true) _loadData();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LightFeatureShortcut(
            icon: Icons.savings_outlined,
            label: 'Budget',
            onTap: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const BudgetSettingsPage()),
              );
              if (updated == true) _loadData();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LightFeatureShortcut(
            icon: Icons.category_outlined,
            label: 'Kategori',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryBudgetsPage()),
              );
              _loadData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLightBudgetSummary() {
    final dailyLimit = _dailyBudget ?? 0;
    final dailyProgress =
        dailyLimit > 0 ? (pengeluaran / dailyLimit).clamp(0.0, 1.0) : 0.0;
    final remaining = dailyLimit > 0
        ? (dailyLimit - pengeluaran).clamp(0, dailyLimit).toDouble()
        : null;

    return BudgetSummaryCard(
      spending: formatCurrency(pengeluaran),
      remaining: remaining == null ? 'Belum diatur' : formatCurrency(remaining),
      progress: dailyProgress,
      caption: dailyLimit > 0
          ? '${(dailyProgress * 100).toStringAsFixed(0)}% dari budget harian'
          : 'Atur budget harian untuk melihat progress.',
    );
  }

  Widget _buildLightMessageCard(String message, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: PokettoLightColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PokettoLightColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              color: PokettoLightColors.secondaryText, size: 42),
          SizedBox(height: 12),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
                color: PokettoLightColors.secondaryText,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderList() {
    final int itemCount = _folders.length > 3 ? 3 : _folders.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Kategori Saya",
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black),
              ),
              if (_folders.length > 3)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AllCategoriesPage()),
                    );
                  },
                  child: const Text(
                    "Lihat Semua",
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _folders.isEmpty
            ? _buildEmptyCategoryPlaceholder()
            : Column(
                children: List.generate(itemCount, (index) {
                  final folder = _folders[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _kategoriItem(
                      name: folder['name'],
                      itemCount: folder['transaction_count'] as int,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FolderDetailPage(
                              folderId: folder['folder_id'] as int,
                              folderName: folder['name'] as String,
                            ),
                          ),
                        ).then((_) {
                          _loadData();
                        });
                      },
                    ),
                  );
                }),
              ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCards() {
    return Column(
      children: _alerts.map((alert) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warningBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetSection() {
    return AppCard(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _budgetTab('Daily Limit', 0),
              const SizedBox(width: 8),
              _budgetTab('Category Limit', 1),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 128,
            child: PageView(
              controller: _budgetPageController,
              onPageChanged: (index) =>
                  setState(() => _budgetPageIndex = index),
              children: [
                _buildDailyLimitPane(),
                _buildCategoryLimitPane(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetTab(String label, int index) {
    final isActive = _budgetPageIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _budgetPageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        },
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AppColors.mutedText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyLimitPane() {
    return _budgetSummaryTile(
      icon: Icons.savings_outlined,
      title: 'Daily Limit',
      value: _dailyBudget != null && _dailyBudget! > 0
          ? formatCurrency(_dailyBudget!)
          : 'Belum diatur',
      onTap: () async {
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const BudgetSettingsPage()),
        );
        if (updated == true) _loadData();
      },
    );
  }

  Widget _buildCategoryLimitPane() {
    if (_expenseCategories.isEmpty) {
      return _budgetSummaryTile(
        icon: Icons.category_outlined,
        title: 'Category Limit',
        value: 'Belum ada kategori',
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryBudgetsPage()),
          );
          _loadData();
        },
      );
    }

    final category = _selectedBudgetCategory() ?? _expenseCategories.first;
    final categoryId = readInt(category['category_id'] ?? category['id']);
    final categoryName = readString(category['name']) ?? 'Kategori';
    final budget = readDouble(category['monthly_budget']);
    final progress =
        categoryId == null ? null : _categoryBudgetProgress[categoryId];
    final spent = readDouble(progress?['spent']) ?? 0;
    final percentage = readDouble(progress?['percentage']) ?? 0;
    final progressValue = readDouble(progress?['progress']) ?? 0;

    return _budgetSummaryTile(
      icon: Icons.account_balance_wallet_outlined,
      title: categoryName,
      value: budget != null && budget > 0
          ? '${formatCurrency(spent)} / ${_formatBudgetInput(budget)}'
          : 'Belum diatur',
      percentage: budget != null && budget > 0 ? percentage : null,
      progressValue: budget != null && budget > 0 ? progressValue : null,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoryBudgetsPage()),
        );
        _loadData();
      },
    );
  }

  Widget _budgetSummaryTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    double? percentage,
    double? progressValue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (progressValue != null && percentage != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: progressValue,
                        backgroundColor: Colors.white,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${percentage.toStringAsFixed(0)}% terpakai',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Atur',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCategoryPlaceholder() {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.create_new_folder_outlined,
                color: Colors.grey, size: 28),
            SizedBox(width: 12),
            Text(
              'Belum ada kategori',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrangeHeader(String currentMonth) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Halo, $userName",
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentMonth,
                        style: AppTextStyles.label,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showProfileMenu(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                          color: AppColors.surface, shape: BoxShape.circle),
                      child: const Icon(Icons.person_outline_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SummaryCard(
                title: 'Saldo Saat Ini',
                amount: formatCurrency(saldo),
                metrics: [
                  _summaryMetric(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Pemasukan',
                    value: formatCurrency(pemasukan),
                    valueColor: Colors.white,
                  ),
                  _summaryDivider(),
                  _summaryMetric(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Pengeluaran',
                    value: '-${formatCurrency(pengeluaran)}',
                    valueColor: Colors.white,
                  ),
                  _summaryDivider(),
                  _summaryMetric(
                    icon: Icons.savings_outlined,
                    label: 'Sisa Jatah',
                    value: _dailyBudget != null && _dailyBudget! > 0
                        ? formatCurrency((_dailyBudget! - pengeluaran)
                            .clamp(0, _dailyBudget!)
                            .toDouble())
                        : 'Belum diatur',
                    valueColor: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1.5,
      height: 42,
      color: Colors.white.withOpacity(0.18),
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _summaryMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: Colors.white70),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBottomNav() {
    return BottomNavBar(
      onHome: hidePopupMenu,
      onAdd: () {
        if (_overlayEntry == null) {
          showPopupMenu();
        } else {
          hidePopupMenu();
        }
      },
      onReports: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MonthlyOverviewPage()),
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMMM', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(userProvider.userName ?? 'User'),
                subtitle: Text(userProvider.userEmail ?? ''),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _handleLogout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin mau logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await AppRepositories.auth.logout();

              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('userId');
              if (!mounted) return;

              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatTransactionLocation(Map<String, dynamic> transaction) {
    final name = readString(transaction['location_name']);
    final lat = readDouble(transaction['location_lat']);
    final lng = readDouble(transaction['location_lng']);
    final isExpense =
        readString(transaction['category_type'] ?? transaction['type']) ==
            'expense';

    if (name != null) return name;
    if (lat != null && lng != null) {
      return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    }
    return isExpense ? 'Lokasi tidak tersedia' : null;
  }

  Widget _transaksiItem({
    required IconData icon,
    required String title,
    required String tanggal,
    required String nominal,
    required bool isPositive,
    String description = '',
    String? locationLabel,
  }) {
    final details = [
      tanggal,
      if (description.isNotEmpty) description,
    ].join(' - ');

    return TransactionListItem(
      icon: icon,
      title: title,
      subtitle: details,
      amount: nominal,
      isIncome: isPositive,
      locationLabel: locationLabel,
    );
  }

  Widget _kategoriItem({
    required String name,
    required int itemCount,
    VoidCallback? onTap,
  }) {
    return CategoryCard(
      icon: Icons.folder_open_rounded,
      title: name,
      subtitle: '$itemCount items',
      onTap: onTap,
    );
  }
}
