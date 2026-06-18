import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:poketto/data/repositories/app_repositories.dart';
import 'package:poketto/providers/theme_controller.dart';
import 'package:poketto/providers/user_provider.dart';
import 'package:poketto/ui/app_feedback.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/app_widgets.dart';
import 'package:poketto/ui/poketto_light_theme.dart';

class BudgetSettingsPage extends StatefulWidget {
  const BudgetSettingsPage({super.key});

  @override
  State<BudgetSettingsPage> createState() => _BudgetSettingsPageState();
}

class _BudgetSettingsPageState extends State<BudgetSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _dailyBudgetController = TextEditingController();
  final _monthlyBudgetController = TextEditingController();
  final _thresholdController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String _currency = 'IDR';
  DateTime? _lastSynced;

  static const _currencies = ['IDR', 'USD', 'EUR', 'SGD', 'JPY'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _dailyBudgetController.dispose();
    _monthlyBudgetController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final userId = context.read<UserProvider>().userId;
      final settings =
          await AppRepositories.userSettings.getSettings(userId: userId);
      if (!mounted) return;
      setState(() {
        final daily = _asDouble(settings['daily_budget']);
        final monthly = _asDouble(settings['monthly_budget']);
        final threshold = _asDouble(settings['budget_warning_threshold']) ?? 80;
        if (daily != null && daily > 0) {
          _dailyBudgetController.text = _formatInput(daily);
        }
        if (monthly != null && monthly > 0) {
          _monthlyBudgetController.text = _formatInput(monthly);
        }
        _thresholdController.text = threshold.toStringAsFixed(0);
        final currency = settings['currency']?.toString() ?? 'IDR';
        _currency = _currencies.contains(currency) ? currency : 'IDR';
        _lastSynced = DateTime.now();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.error(context, 'Pengaturan belum bisa dimuat. Coba lagi.');
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final userId = context.read<UserProvider>().userId;
      await AppRepositories.userSettings.updateSettings({
        'daily_budget': _parseCurrency(_dailyBudgetController.text),
        'monthly_budget': _parseCurrency(_monthlyBudgetController.text),
        'currency': _currency,
        'budget_warning_threshold':
            double.parse(_thresholdController.text.trim()),
        // Backend dan web berbagi preference ini. Menyimpan Settings dari
        // mobile selalu mengaktifkan kembali notification presentation.
        'notification_enabled': true,
      }, userId: userId);
      if (!mounted) return;
      setState(() => _lastSynced = DateTime.now());
      AppFeedback.success(context, 'Settings berhasil disimpan.');
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error(context, 'Settings gagal disimpan. Coba lagi nanti.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  double? _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value');

  String? _validateBudget(String? value) {
    final amount = _parseCurrency(value ?? '');
    if (amount == null) return 'Budget wajib diisi angka';
    if (amount < 0) return 'Budget tidak boleh negatif';
    return null;
  }

  String? _validateThreshold(String? value) {
    final threshold = double.tryParse((value ?? '').trim());
    if (threshold == null) return 'Threshold wajib diisi angka';
    if (threshold < 1 || threshold > 100) return 'Gunakan nilai 1–100';
    return null;
  }

  void _formatAmount(TextEditingController controller) {
    final amount = _parseCurrency(controller.text);
    if (amount == null) {
      controller.clear();
      return;
    }
    final formatted = _formatInput(amount);
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatInput(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(amount.toInt()).replaceAll(',', '.')}';
  }

  double? _parseCurrency(String value) {
    final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericValue.isEmpty) return null;
    return double.tryParse(numericValue);
  }

  void _navigate(int index) {
    if (index == 3) return;
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    Navigator.pushReplacementNamed(
        context, index == 1 ? '/history' : '/categories');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final themeController = context.watch<ThemeController>();
    final theme = Theme.of(context);
    final semantic = context.poketto;

    return PokettoGradientScaffold(
      appBar: AppBar(
          title: const Text('Pengaturan'), backgroundColor: Colors.transparent),
      bottomNavigationBar: PokettoBottomNav(
        currentIndex: 3,
        onDestinationSelected: _navigate,
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    AppCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: semantic.softSurface,
                            child: Icon(Icons.person_rounded,
                                color: theme.colorScheme.primary, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.userName ?? 'Pengguna',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text(
                                  user.userEmail ?? 'ID: ${user.userId ?? '-'}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: semantic.mutedText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 10),
                              const Text('Manajemen Anggaran',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _label('Daily budget'),
                          TextFormField(
                            controller: _dailyBudgetController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (_) =>
                                _formatAmount(_dailyBudgetController),
                            validator: _validateBudget,
                            decoration:
                                const InputDecoration(hintText: 'Rp 100.000'),
                          ),
                          const SizedBox(height: 18),
                          _label('Monthly budget'),
                          TextFormField(
                            controller: _monthlyBudgetController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (_) =>
                                _formatAmount(_monthlyBudgetController),
                            validator: _validateBudget,
                            decoration:
                                const InputDecoration(hintText: 'Rp 5.000.000'),
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(builder: (context, constraints) {
                            final narrow = constraints.maxWidth < 330;
                            final currency = DropdownButtonFormField<String>(
                              value: _currency,
                              decoration:
                                  const InputDecoration(labelText: 'Currency'),
                              items: _currencies
                                  .map((value) => DropdownMenuItem(
                                      value: value, child: Text(value)))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _currency = value ?? 'IDR'),
                            );
                            final threshold = TextFormField(
                              controller: _thresholdController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: _validateThreshold,
                              decoration: const InputDecoration(
                                labelText: 'Warning threshold',
                                suffixText: '%',
                              ),
                            );
                            if (narrow) {
                              return Column(children: [
                                currency,
                                const SizedBox(height: 14),
                                threshold
                              ]);
                            }
                            return Row(children: [
                              Expanded(child: currency),
                              const SizedBox(width: 12),
                              Expanded(child: threshold),
                            ]);
                          }),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: semantic.softSurface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.notifications_active_outlined,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Peringatan budget aktif secara default dan tersedia melalui ikon lonceng.',
                                    style: TextStyle(
                                        color: semantic.mutedText,
                                        fontSize: 12.5,
                                        height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(
                                themeController.isDarkMode
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: theme.colorScheme.primary),
                            title: const Text('Dark mode',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(
                              themeController.isDarkMode
                                  ? 'Tema gelap aktif'
                                  : 'Tema terang aktif',
                              style: TextStyle(color: semantic.mutedText),
                            ),
                            value: themeController.isDarkMode,
                            onChanged: themeController.setDarkMode,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 56,
                      child: AppButton(
                        label: 'Simpan settings',
                        icon: Icons.save_outlined,
                        isLoading: _isSaving,
                        onPressed: _saveSettings,
                      ),
                    ),
                    if (_lastSynced != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Last synced: ${DateFormat('HH:mm').format(_lastSynced!)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: semantic.mutedText),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _label(String label) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      );
}
