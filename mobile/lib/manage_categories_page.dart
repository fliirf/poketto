import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/data/repositories/app_repositories.dart';
import 'package:poketto/providers/user_provider.dart';
import 'package:poketto/ui/app_feedback.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/app_widgets.dart';
import 'package:poketto/ui/poketto_light_theme.dart';

class ManageCategoriesPage extends StatefulWidget {
  final String? initialAddType;

  const ManageCategoriesPage({super.key, this.initialAddType});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  List<Map<String, dynamic>> _incomeCategories = [];
  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _monthlyTransactions = [];
  bool _isLoading = true;
  bool _isSavingCategory = false;
  bool _isDeletingCategory = false;

  @override
  void initState() {
    super.initState();
    _loadCategories(showInitialDialog: widget.initialAddType != null);
  }

  Future<void> _loadCategories({bool showInitialDialog = false}) async {
    setState(() => _isLoading = true);

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final results = await Future.wait([
        AppRepositories.categories.getCategoriesForUi(
          type: 'income',
          userId: userId,
        ),
        AppRepositories.categories.getCategoriesForUi(
          type: 'expense',
          userId: userId,
        ),
        AppRepositories.transactions.getTransactionsByMonthForUi(
          userId: userId,
          month: currentMonth,
        ),
      ]);
      final income = results[0];
      final expense = results[1];
      final transactions = results[2];
      if (!mounted) return;

      setState(() {
        _incomeCategories = income;
        _expenseCategories = expense;
        _monthlyTransactions = transactions;
        _isLoading = false;
      });

      if (showInitialDialog && widget.initialAddType != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showCategoryDialog(widget.initialAddType!);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.error(context, 'Kategori belum bisa dimuat. Coba lagi.');
    }
  }

  Future<void> _showCategoryDialog(
    String type, {
    Map<String, dynamic>? category,
  }) async {
    final isEdit = category != null;
    final nameController = TextEditingController(
      text: readString(category?['name']) ?? '',
    );
    final budgetController = TextEditingController(
      text: _formatBudgetInput(readDouble(category?['monthly_budget'])),
    );
    final formKey = GlobalKey<FormState>();
    var selectedType = type;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    textInputAction: selectedType == 'expense'
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (selectedType != 'expense') {
                        _submitCategoryDialog(
                          isEdit: isEdit,
                          type: selectedType,
                          category: category,
                          nameController: nameController,
                          budgetController: budgetController,
                          formKey: formKey,
                        );
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Nama Kategori',
                      hintText: selectedType == 'income'
                          ? 'Contoh: Freelance'
                          : 'Contoh: Kopi',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama kategori tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  if (!isEdit) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Tipe'),
                      items: const [
                        DropdownMenuItem(
                            value: 'expense', child: Text('Pengeluaran')),
                        DropdownMenuItem(
                            value: 'income', child: Text('Pemasukan')),
                      ],
                      onChanged: (value) => setDialogState(
                          () => selectedType = value ?? selectedType),
                    ),
                  ],
                  if (selectedType == 'expense') ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) =>
                          _formatBudgetField(budgetController),
                      decoration: const InputDecoration(
                        labelText: 'Budget Bulanan (Opsional)',
                        hintText: 'Rp. 100.000',
                      ),
                      validator: (value) {
                        final amount = _parseCurrency(value ?? '');
                        if (value == null || value.trim().isEmpty) return null;
                        if (amount == null || amount <= 0) {
                          return 'Budget harus angka lebih dari 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isSavingCategory
                  ? null
                  : () => _submitCategoryDialog(
                        isEdit: isEdit,
                        type: selectedType,
                        category: category,
                        nameController: nameController,
                        budgetController: budgetController,
                        formKey: formKey,
                      ),
              child: _isSavingCategory
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(isEdit ? 'Simpan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCategoryDialog({
    required bool isEdit,
    required String type,
    required Map<String, dynamic>? category,
    required TextEditingController nameController,
    required TextEditingController budgetController,
    required GlobalKey<FormState> formKey,
  }) async {
    final name = nameController.text.trim();
    final monthlyBudget =
        type == 'expense' ? _parseCurrency(budgetController.text) : null;

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (_isSavingCategory) return;
    setState(() => _isSavingCategory = true);

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      final result = isEdit
          ? await AppRepositories.categories.updateCategoryForUi(
              categoryId: readInt(category?['category_id']) ?? 0,
              name: name,
              type: type,
              monthlyBudget: monthlyBudget,
              userId: userId,
            )
          : await AppRepositories.categories.createCategoryForUi(
              name: name,
              type: type,
              monthlyBudget: monthlyBudget,
              userId: userId,
            );

      if (!mounted) return;
      Navigator.pop(context);

      if (result > 0) {
        AppFeedback.success(
          context,
          isEdit
              ? 'Kategori berhasil diperbarui.'
              : 'Kategori berhasil ditambahkan.',
        );
        _loadCategories();
      } else {
        _showCategoryError('Kategori gagal disimpan.');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showCategoryError(e.userMessage);
    } catch (e) {
      if (!mounted) return;
      _showCategoryError('Kategori gagal disimpan.');
    } finally {
      if (mounted) setState(() => _isSavingCategory = false);
    }
  }

  Future<void> _showDeleteCategoryDialog(
    Map<String, dynamic> category,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kategori?'),
        content: Text(
          'Yakin ingin menghapus kategori "${category['name']}"?\n\n'
          'Kategori yang masih digunakan dalam transaksi tidak dapat dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (_isDeletingCategory) return;

    setState(() => _isDeletingCategory = true);

    try {
      final result = await AppRepositories.categories.deleteCategoryForUi(
        readInt(category['category_id']) ?? 0,
      );

      if (!mounted) return;

      if (result > 0) {
        AppFeedback.success(context, 'Kategori berhasil dihapus.');
        _loadCategories();
      } else {
        _showCategoryError('Kategori masih digunakan dalam transaksi.');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showCategoryError(e.userMessage);
    } catch (_) {
      if (!mounted) return;
      _showCategoryError('Kategori gagal dihapus.');
    } finally {
      if (mounted) setState(() => _isDeletingCategory = false);
    }
  }

  void _showCategoryError(String message) {
    AppFeedback.error(context, message);
  }

  void _formatBudgetField(TextEditingController controller) {
    final amount = _parseCurrency(controller.text);
    if (amount == null) {
      controller.text = '';
      return;
    }

    final formatted = _formatBudgetInput(amount);
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatBudgetInput(double? amount) {
    if (amount == null || amount <= 0) return '';
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp. ${formatter.format(amount.toInt()).replaceAll(',', '.')}';
  }

  double? _parseCurrency(String value) {
    final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericValue.isEmpty) return null;
    return double.tryParse(numericValue);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return PokettoGradientScaffold(
      bottomNavigationBar: PokettoBottomNav(
        currentIndex: 2,
        onDestinationSelected: _navigate,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back,
                        size: 28, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Kelola Kategori',
                    style: AppTextStyles.title,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadCategories,
                        child: ListView(
                          children: [
                            Text(
                              'Kelola kategori pemasukan, pengeluaran, dan budget bulanan.',
                              style:
                                  TextStyle(color: context.poketto.mutedText),
                            ),
                            const SizedBox(height: 20),
                            _buildSectionHeader(
                              'Kategori Pemasukan',
                              () => _showCategoryDialog('income'),
                            ),
                            const SizedBox(height: 12),
                            if (_incomeCategories.isEmpty)
                              _buildEmptyState('Belum ada kategori pemasukan'),
                            ..._incomeCategories.map(_buildCategoryItem),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              'Kategori Pengeluaran',
                              () => _showCategoryDialog('expense'),
                            ),
                            const SizedBox(height: 12),
                            if (_expenseCategories.isEmpty)
                              _buildEmptyState(
                                  'Belum ada kategori pengeluaran'),
                            ..._expenseCategories.map(_buildCategoryItem),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.sectionTitle,
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline),
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: context.poketto.mutedText)),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final type = readString(category['type']) ?? 'expense';
    final monthlyBudget = readDouble(category['monthly_budget']);
    final categoryId = readInt(category['category_id'] ?? category['id']);
    final used = _monthlyTransactions.fold<double>(0, (total, tx) {
      final txCategoryId = readInt(tx['category_id'] ?? tx['categoryId']);
      final txType = readString(tx['category_type'] ?? tx['type']);
      if (txCategoryId != categoryId || txType != type) return total;
      return total + (readDouble(tx['amount']) ?? 0);
    });
    final progress =
        monthlyBudget != null && monthlyBudget > 0 ? used / monthlyBudget : 0.0;
    final exceeded = progress >= 1;
    final warning = progress >= .75;
    final statusColor = exceeded
        ? context.poketto.expense
        : warning
            ? context.poketto.warning
            : context.poketto.income;
    final title = readString(category['name']) ?? 'Kategori';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type == 'income' ? 'PEMASUKAN' : 'PENGELUARAN',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            type == 'income'
                ? 'Total bulan ini: ${_formatCurrency(used)}'
                : monthlyBudget != null && monthlyBudget > 0
                    ? 'Budget: ${_formatCurrency(monthlyBudget)}'
                    : 'Budget bulanan belum diatur',
            style: TextStyle(color: context.poketto.mutedText),
          ),
          if (type == 'expense' &&
              monthlyBudget != null &&
              monthlyBudget > 0) ...[
            const SizedBox(height: 5),
            Text(
              exceeded
                  ? 'Melebihi budget!'
                  : warning
                      ? '${(progress * 100).toStringAsFixed(0)}% terpakai'
                      : 'Status aman',
              style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text('${_formatCurrency(used)} digunakan',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: progress.clamp(0, 1),
                color: statusColor,
                backgroundColor: context.poketto.softSurface,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _isDeletingCategory
                    ? null
                    : () => _showCategoryDialog(type, category: category),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: _isDeletingCategory
                    ? null
                    : () => _showDeleteCategoryDialog(category),
                icon: const Icon(Icons.delete_outline, size: 17),
                label: const Text('Hapus'),
                style: TextButton.styleFrom(
                    foregroundColor: context.poketto.expense),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigate(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    Navigator.pushReplacementNamed(
        context, index == 1 ? '/history' : '/settings');
  }
}
