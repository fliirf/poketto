import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:poketto/core/debug/category_debug.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/data/repositories/app_repositories.dart';
import 'package:poketto/providers/user_provider.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/app_widgets.dart';

class ManageCategoriesPage extends StatefulWidget {
  final String? initialAddType;

  const ManageCategoriesPage({super.key, this.initialAddType});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  List<Map<String, dynamic>> _incomeCategories = [];
  List<Map<String, dynamic>> _expenseCategories = [];
  bool _isLoading = true;
  bool _isSavingCategory = false;

  @override
  void initState() {
    super.initState();
    _loadCategories(showInitialDialog: widget.initialAddType != null);
  }

  Future<void> _loadCategories({bool showInitialDialog = false}) async {
    setState(() => _isLoading = true);

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      final results = await Future.wait([
        AppRepositories.categories.getCategoriesForUi(
          type: 'income',
          userId: userId,
        ),
        AppRepositories.categories.getCategoriesForUi(
          type: 'expense',
          userId: userId,
        ),
      ]);
      final income = results[0];
      final expense = results[1];
      logCategoryFlow(
        'loadCategories userId=$userId income=${income.length} expense=${expense.length}',
      );

      if (!mounted) return;

      setState(() {
        _incomeCategories = income;
        _expenseCategories = expense;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori belum bisa dimuat. Coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
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

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  textInputAction: type == 'expense'
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (type != 'expense') {
                      _submitCategoryDialog(
                        isEdit: isEdit,
                        type: type,
                        category: category,
                        nameController: nameController,
                        budgetController: budgetController,
                        formKey: formKey,
                      );
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori',
                    hintText:
                        type == 'income' ? 'Contoh: Freelance' : 'Contoh: Kopi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama kategori tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                if (type == 'expense') ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _formatBudgetField(budgetController),
                    decoration: InputDecoration(
                      labelText: 'Budget Bulanan (Opsional)',
                      hintText: 'Rp. 100.000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                      type: type,
                      category: category,
                      nameController: nameController,
                      budgetController: budgetController,
                      formKey: formKey,
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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

    logCategoryFlow(
      'submit tapped isEdit=$isEdit type=$type name="$name" budgetText="${budgetController.text}" monthlyBudget=$monthlyBudget',
    );

    if (!formKey.currentState!.validate()) {
      logCategoryFlow('submit blocked by validation name="$name"');
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

      logCategoryFlow('repository result=$result');

      if (!mounted) return;
      Navigator.pop(context);

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Kategori berhasil diupdate'
                : 'Kategori berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        logCategoryFlow('refresh called after successful save');
        _loadCategories();
      } else {
        _showCategoryError('Kategori gagal disimpan.');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      logCategoryFlow(
        'submit ApiException status=${e.statusCode} message=${e.message}',
      );
      _showCategoryError(e.userMessage);
    } catch (e) {
      if (!mounted) return;
      logCategoryFlow('submit unexpected error=$e');
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

    try {
      final result = await AppRepositories.categories.deleteCategoryForUi(
        readInt(category['category_id']) ?? 0,
      );

      if (!mounted) return;

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }

  void _showCategoryError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        size: 28, color: AppColors.primary),
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
                decoration: const BoxDecoration(
                  color: AppColors.background,
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
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black54)),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final type = readString(category['type']) ?? 'expense';
    final monthlyBudget = readDouble(category['monthly_budget']);

    return CategoryCard(
      icon: Icons.category_outlined,
      title: readString(category['name']) ?? 'Kategori',
      subtitle: type == 'income'
          ? 'Pemasukan'
          : monthlyBudget != null && monthlyBudget > 0
              ? 'Budget: ${_formatCurrency(monthlyBudget)}'
              : 'Budget bulanan belum diatur',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _showCategoryDialog(type, category: category),
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.primary,
          ),
          IconButton(
            onPressed: () => _showDeleteCategoryDialog(category),
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
