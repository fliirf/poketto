import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/data/repositories/app_repositories.dart';
import 'package:poketto/providers/user_provider.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/app_widgets.dart';

class CategoryBudgetsPage extends StatefulWidget {
  const CategoryBudgetsPage({super.key});

  @override
  State<CategoryBudgetsPage> createState() => _CategoryBudgetsPageState();
}

class _CategoryBudgetsPageState extends State<CategoryBudgetsPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      final categories = await AppRepositories.categories.getCategoriesForUi(
        type: 'expense',
        userId: userId,
      );

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget kategori belum bisa dimuat. Coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditBudgetDialog(Map<String, dynamic> category) async {
    final nameController = TextEditingController(
      text: readString(category['name']) ?? '',
    );
    final budgetController = TextEditingController(
      text: _formatBudgetInput(readDouble(category['monthly_budget'])),
    );
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Budget Kategori'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Kategori',
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
              const SizedBox(height: 14),
              TextFormField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _formatBudgetField(budgetController),
                decoration: InputDecoration(
                  labelText: 'Monthly Budget',
                  hintText: 'Rp. 100.000',
                  helperText: 'Kosongkan jika tidak ingin dihitung warning.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final amount = _parseCurrency(value);
                  if (amount == null || amount <= 0) {
                    return 'Budget harus angka lebih dari 0';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final categoryId = readInt(category['category_id']);
              if (categoryId == null) {
                Navigator.pop(context);
                return;
              }

              final userId =
                  Provider.of<UserProvider>(context, listen: false).userId;
              final monthlyBudget = _parseCurrency(budgetController.text);

              try {
                final result =
                    await AppRepositories.categories.updateCategoryForUi(
                  categoryId: categoryId,
                  name: nameController.text.trim(),
                  type: readString(category['type']) ?? 'expense',
                  monthlyBudget: monthlyBudget,
                  userId: userId,
                );

                if (!mounted) return;
                Navigator.pop(context);

                if (result > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Budget kategori berhasil disimpan.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadCategories();
                } else {
                  _showError('Budget kategori gagal disimpan.');
                }
              } on ApiException catch (e) {
                if (!mounted) return;
                _showError(e.userMessage);
              } catch (_) {
                if (!mounted) return;
                _showError('Budget kategori gagal disimpan.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
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
                    onTap: () => Navigator.pop(context, true),
                    child: const Icon(Icons.arrow_back,
                        size: 28, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Budget Kategori',
                      style: AppTextStyles.title,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
                        child: _categories.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  Center(
                                    child: Text(
                                      'Belum ada kategori pengeluaran.',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                itemCount: _categories.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return AppCard(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(16),
                                      child: const Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Budget bulanan dipakai untuk warning saat pengeluaran kategori mencapai 80%.',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final category = _categories[index - 1];
                                  final budget =
                                      readDouble(category['monthly_budget']);
                                  final hasBudget =
                                      budget != null && budget > 0;

                                  return CategoryCard(
                                    icon: Icons.account_balance_wallet_outlined,
                                    title: readString(category['name']) ??
                                        'Kategori',
                                    subtitle: hasBudget
                                        ? 'Budget: ${_formatCurrency(budget)}'
                                        : 'Belum diset',
                                    trailing: TextButton(
                                      onPressed: () =>
                                          _showEditBudgetDialog(category),
                                      child: const Text('Edit'),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
