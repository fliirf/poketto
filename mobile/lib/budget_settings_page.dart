import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:poketto/data/repositories/app_repositories.dart';
import 'package:poketto/providers/user_provider.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/app_widgets.dart';

class BudgetSettingsPage extends StatefulWidget {
  const BudgetSettingsPage({super.key});

  @override
  State<BudgetSettingsPage> createState() => _BudgetSettingsPageState();
}

class _BudgetSettingsPageState extends State<BudgetSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _dailyBudgetController = TextEditingController();
  final _thresholdController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  @override
  void dispose() {
    _dailyBudgetController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadBudget() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      final results = await Future.wait<double?>([
        AppRepositories.userSettings.getDailyBudget(userId: userId),
        AppRepositories.userSettings.getBudgetWarningThreshold(userId: userId),
      ]);
      final effectiveBudget = results[0] ?? 0;
      final warningThreshold = results[1] ?? 80;

      if (!mounted) return;
      setState(() {
        if (effectiveBudget > 0) {
          _dailyBudgetController.text = _formatInput(effectiveBudget);
        }
        _thresholdController.text = warningThreshold.toStringAsFixed(0);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading budget settings: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan budget belum bisa dimuat. Coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      final amount = _parseCurrency(_dailyBudgetController.text)!;
      final threshold = double.parse(_thresholdController.text.trim());
      await AppRepositories.userSettings.setDailyBudget(
        amount,
        userId: userId,
      );
      await AppRepositories.userSettings.setBudgetWarningThreshold(
        threshold,
        userId: userId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget harian berhasil disimpan.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateBudget(String? value) {
    final amount = _parseCurrency(value ?? '');
    if (amount == null) return 'Daily budget wajib diisi angka';
    if (amount <= 0) return 'Daily budget harus lebih dari 0';
    return null;
  }

  String? _validateThreshold(String? value) {
    final threshold = double.tryParse((value ?? '').trim());
    if (threshold == null) return 'Threshold wajib diisi angka';
    if (threshold <= 0 || threshold >= 100) {
      return 'Threshold harus antara 1 dan 99';
    }
    return null;
  }

  void _formatAmount(String value) {
    final amount = _parseCurrency(value);
    if (amount == null) {
      _dailyBudgetController.text = '';
      return;
    }

    final formatted = _formatInput(amount);
    _dailyBudgetController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatInput(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp. ${formatter.format(amount.toInt()).replaceAll(',', '.')}';
  }

  double? _parseCurrency(String value) {
    final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericValue.isEmpty) return null;
    return double.tryParse(numericValue);
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
                    onTap: () => Navigator.pop(context, false),
                    child: const Icon(Icons.arrow_back,
                        size: 28, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pengaturan Budget',
                    style: AppTextStyles.title,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Budget Harian',
                                style: AppTextStyles.sectionTitle),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _dailyBudgetController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: _formatAmount,
                              validator: _validateBudget,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.savings_outlined),
                                hintText: 'Rp. 100.000',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Batas Peringatan',
                                style: AppTextStyles.sectionTitle),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _thresholdController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: _validateThreshold,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon:
                                    const Icon(Icons.notifications_outlined),
                                suffixText: '%',
                                hintText: '80',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppCard(
                              padding: const EdgeInsets.all(14),
                              color: AppColors.warningBg,
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Notifikasi warning muncul saat pengeluaran mencapai persentase threshold. Notifikasi exceeded muncul saat limit terlampaui.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                onPressed: _isSaving ? null : _saveBudget,
                                isLoading: _isSaving,
                                label: 'Simpan Budget',
                              ),
                            ),
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
}
