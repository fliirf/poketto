import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/data/repositories/app_repositories.dart';
import 'package:poketto/data/services/location_service.dart';
import 'package:poketto/database/database_helper.dart';
import 'package:poketto/providers/user_provider.dart';
import 'package:poketto/manage_categories_page.dart';
import 'package:poketto/ui/app_feedback.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/app_widgets.dart';

class AddTransactionPage extends StatefulWidget {
  final Map<String, dynamic>? transaction;

  const AddTransactionPage({
    super.key,
    this.transaction,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool isIncome = true;
  int? selectedCategoryId;
  int? selectedBudgetId;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool _attachLocation = true;
  bool _isResolvingLocation = false;
  String? _locationMessage;
  double? _locationLat;
  double? _locationLng;
  String? _locationName;

  List<Map<String, dynamic>> incomeCategories = [];
  List<Map<String, dynamic>> expenseCategories = [];
  List<Map<String, dynamic>> activeTargets = [];

  bool get isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadActiveTargets();
    if (isEditMode) {
      _initializeEditData();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initializeEditData() {
    final transaction = widget.transaction!;

    final amount = readDouble(transaction['amount']) ?? 0;
    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(amount.toInt());
    _amountController.text = 'Rp. ${formatted.replaceAll(',', '.')}';

    _noteController.text = readString(transaction['description']) ?? '';

    selectedDate = readDateTime(
          transaction['transaction_date'] ?? transaction['date'],
        ) ??
        DateTime.now();

    selectedCategoryId = readInt(transaction['category_id']);
    selectedBudgetId = readInt(transaction['budget_id']);

    final categoryType = readString(
      transaction['category_type'] ?? transaction['type'],
    );
    isIncome = categoryType == 'income';
    _attachLocation = !isIncome;
    _locationLat = readDouble(transaction['location_lat']);
    _locationLng = readDouble(transaction['location_lng']);
    _locationName = readString(transaction['location_name']);
    if (!isIncome && (_locationLat != null || _locationLng != null)) {
      _locationMessage = _formatLocationStatus();
    }
  }

  Future<void> _loadCategories() async {
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

      if (!mounted) return;

      setState(() {
        incomeCategories = income;
        expenseCategories = expense;

        if (!isEditMode) {
          if (isIncome && incomeCategories.isNotEmpty) {
            selectedCategoryId = incomeCategories.first['category_id'] as int;
          } else if (!isIncome && expenseCategories.isNotEmpty) {
            selectedCategoryId = expenseCategories.first['category_id'] as int;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, 'Kategori belum bisa dimuat. Coba lagi.');
    }
  }

  Future<void> _loadActiveTargets() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;

      if (userId == null) return;

      final db = DatabaseHelper.instance;
      final targets = await db.getActiveTargets(userId);

      if (!mounted) return;

      setState(() {
        activeTargets = targets;
      });
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, 'Target belum bisa dimuat. Coba lagi.');
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty) {
      AppFeedback.error(context, 'Nominal wajib diisi.');
      return;
    }

    if (selectedCategoryId == null) {
      AppFeedback.error(context, 'Kategori wajib dipilih.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final amountStr = _amountController.text
          .replaceAll('Rp. ', '')
          .replaceAll('.', '')
          .trim();
      final amount = double.parse(amountStr);
      if (amount <= 0) {
        throw const FormatException('Jumlah harus lebih dari 0');
      }

      final description = _noteController.text.isEmpty
          ? 'Transaksi ${isIncome ? "pemasukan" : "pengeluaran"}'
          : _noteController.text;
      TransactionLocation? location;
      if (!isIncome && _attachLocation) {
        if (mounted) {
          setState(() {
            _isResolvingLocation = true;
            _locationMessage = 'Mengambil lokasi...';
          });
        }

        location = await _resolveLocationSafely();
        if (!location.hasCoordinate && isEditMode) {
          location = TransactionLocation(
            latitude: readDouble(widget.transaction?['location_lat']),
            longitude: readDouble(widget.transaction?['location_lng']),
            name: readString(widget.transaction?['location_name']),
            message: location.message,
          );
        }
        if (mounted) {
          setState(() {
            _isResolvingLocation = false;
            _locationLat = location?.latitude;
            _locationLng = location?.longitude;
            _locationName = location?.name;
            _locationMessage = location?.statusLabel;
          });
        }
      } else {
        setState(() {
          _isResolvingLocation = false;
          _locationMessage = isIncome ? null : 'Lokasi dilewati';
          _locationLat = null;
          _locationLng = null;
          _locationName = null;
        });
      }

      int result;

      if (isEditMode) {
        final transactionId = widget.transaction!['transaction_id'] as int;
        result = await AppRepositories.transactions.updateTransaction(
          transactionId: transactionId,
          categoryId: selectedCategoryId!,
          type: isIncome ? 'income' : 'expense',
          amount: amount,
          description: description,
          transactionDate: selectedDate,
          budgetId: selectedBudgetId,
          location: location,
        );
      } else {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.userId;

        if (userId == null) {
          throw Exception('User tidak ditemukan');
        }

        result = await AppRepositories.transactions.createTransaction(
          userId: userId,
          categoryId: selectedCategoryId!,
          type: isIncome ? 'income' : 'expense',
          amount: amount,
          description: description,
          transactionDate: selectedDate,
          budgetId: selectedBudgetId,
          location: location,
        );
      }

      if (!mounted) return;

      if (result > 0) {
        await _checkBudgetNotifications();
        AppFeedback.success(
          context,
          isEditMode
              ? 'Transaksi berhasil diperbarui.'
              : isIncome
                  ? 'Berhasil tambah pemasukan.'
                  : 'Berhasil tambah pengeluaran.',
        );
        if (_locationMessage != null) {
          AppFeedback.info(context, _locationMessage!,
              color: AppColors.primary);
        }
        Navigator.pop(context, true);
      } else {
        throw Exception('Gagal menyimpan transaksi');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.userMessage);
    } on FormatException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context,
          'Gagal menyimpan transaksi. Periksa kembali data yang diisi.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      final transactionId = widget.transaction!['transaction_id'] as int;

      final result = await AppRepositories.transactions.deleteTransaction(
        transactionId,
      );

      if (!mounted) return;

      if (result > 0) {
        await _checkBudgetNotifications();
        AppFeedback.success(context, 'Transaksi berhasil dihapus.');
        Navigator.pop(context, true);
      } else {
        throw Exception('Gagal menghapus transaksi');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.userMessage);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, 'Transaksi gagal dihapus. Coba lagi nanti.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _formatAmount(String value) {
    if (value.isEmpty) return;

    final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (numericValue.isEmpty) {
      _amountController.text = '';
      return;
    }

    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(int.parse(numericValue));

    _amountController.value = TextEditingValue(
      text: 'Rp. ${formatted.replaceAll(',', '.')}',
      selection: TextSelection.collapsed(
        offset: 'Rp. ${formatted.replaceAll(',', '.')}'.length,
      ),
    );
  }

  Future<TransactionLocation> _resolveLocationSafely() async {
    try {
      return await AppRepositories.location.getCurrentTransactionLocation();
    } catch (error) {
      return const TransactionLocation(
        message:
            'Lokasi tidak berhasil diambil. Transaksi tetap disimpan tanpa lokasi.',
      );
    }
  }

  Future<void> _checkBudgetNotifications() async {
    try {
      final alerts = await AppRepositories.budgetAlerts.getRemoteAlerts();
      await AppRepositories.notifications.showBudgetAlerts(alerts);
    } catch (error) {
      return;
    }
  }

  String _formatLocationStatus() {
    if (_isResolvingLocation) return 'Mengambil lokasi...';
    if (!_attachLocation) return 'Lokasi dilewati';

    if (_locationLat != null && _locationLng != null) {
      if (_locationName != null && _locationName!.trim().isNotEmpty) {
        return 'Lokasi berhasil: $_locationName';
      }
      return 'Lokasi berhasil: ${_locationLat!.toStringAsFixed(6)}, ${_locationLng!.toStringAsFixed(6)}';
    }

    return _locationMessage ?? 'Lokasi akan dicoba saat disimpan';
  }

  Widget _buildLocationSection() {
    if (isIncome) return const SizedBox.shrink();

    final hasCoordinate = _locationLat != null && _locationLng != null;

    return Column(
      children: [
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                value: _attachLocation,
                onChanged: isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _attachLocation = value;
                          if (!value) {
                            _locationLat = null;
                            _locationLng = null;
                            _locationName = null;
                          }
                          _locationMessage =
                              value ? 'Lokasi akan dicoba saat disimpan' : null;
                        });
                      },
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                secondary: Icon(
                  _attachLocation
                      ? Icons.location_on_outlined
                      : Icons.location_off_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Tambahkan lokasi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _formatLocationStatus(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (hasCoordinate) ...[
                const Divider(height: 18),
                const Text(
                  'Lokasi',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                if (_locationName != null && _locationName!.trim().isNotEmpty)
                  Text(
                    _locationName!,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                Text(
                  'Lat: ${_locationLat!.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  'Lng: ${_locationLng!.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _formLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 7),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _fieldShell({
    required IconData icon,
    required Widget child,
    double minHeight = 56,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 14),
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: minHeight > 70
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: minHeight > 70 ? 14 : 0),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _transactionTypeSegment() {
    Widget item({
      required bool active,
      required String label,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: isLoading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active ? Colors.white : AppColors.mutedText,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          item(
            active: isIncome,
            label: 'Pemasukan',
            icon: Icons.arrow_downward_rounded,
            onTap: () {
              setState(() {
                isIncome = true;
                _attachLocation = false;
                _locationMessage = null;
                _locationLat = null;
                _locationLng = null;
                _locationName = null;
                if (incomeCategories.isNotEmpty) {
                  selectedCategoryId =
                      incomeCategories.first['category_id'] as int;
                }
              });
            },
          ),
          const SizedBox(width: 6),
          item(
            active: !isIncome,
            label: 'Pengeluaran',
            icon: Icons.arrow_upward_rounded,
            onTap: () {
              setState(() {
                isIncome = false;
                _attachLocation = true;
                _locationMessage = null;
                _locationLat = null;
                _locationLng = null;
                _locationName = null;
                if (expenseCategories.isNotEmpty) {
                  selectedCategoryId =
                      expenseCategories.first['category_id'] as int;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCategories = isIncome ? incomeCategories : expenseCategories;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.primary,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        shape: const CircleBorder(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi',
                        style: AppTextStyles.title,
                      ),
                    ),
                    if (isEditMode)
                      IconButton(
                        onPressed: isLoading ? null : _deleteTransaction,
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: Colors.red,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.09),
                          shape: const CircleBorder(),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _transactionTypeSegment(),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _formLabel('Jumlah'),
                      _fieldShell(
                        icon: Icons.payments_outlined,
                        minHeight: 58,
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: _formatAmount,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            hintText: 'Rp 0',
                            hintStyle: TextStyle(
                              color: Colors.black26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _formLabel('Kategori'),
                      Row(
                        children: [
                          Expanded(
                            child: _fieldShell(
                              icon: Icons.category_outlined,
                              child: currentCategories.isEmpty
                                  ? const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 17),
                                      child: Text(
                                        'Belum ada kategori...',
                                        style: TextStyle(
                                          color: AppColors.mutedText,
                                        ),
                                      ),
                                    )
                                  : DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<int>(
                                        value: selectedCategoryId,
                                        isExpanded: true,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: AppColors.mutedText,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        items:
                                            currentCategories.map((category) {
                                          return DropdownMenuItem<int>(
                                            value:
                                                category['category_id'] as int,
                                            child: Text(
                                              category['name'] as String,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(
                                            () => selectedCategoryId = value,
                                          );
                                        },
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 54,
                            height: 54,
                            child: IconButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ManageCategoriesPage(),
                                  ),
                                );
                                _loadCategories();
                              },
                              icon: const Icon(Icons.tune_rounded),
                              color: Colors.white,
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isIncome && activeTargets.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _formLabel('Target (Opsional)'),
                        _fieldShell(
                          icon: Icons.flag_outlined,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<int?>(
                              value: selectedBudgetId,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.mutedText,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              hint: const Text('Tidak ada target'),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Tidak ada target'),
                                ),
                                ...activeTargets.map(
                                  (target) => DropdownMenuItem<int?>(
                                    value: target['budget_id'] as int,
                                    child: Text(
                                      target['name'] as String,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => selectedBudgetId = value);
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _formLabel('Tanggal'),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDate: selectedDate,
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        child: _fieldShell(
                          icon: Icons.calendar_today_outlined,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('d MMMM yyyy')
                                      .format(selectedDate),
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.mutedText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _formLabel('Deskripsi / Catatan'),
                      _fieldShell(
                        icon: Icons.edit_note_rounded,
                        minHeight: 108,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 4,
                          minLines: 3,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'Contoh: Makan siang',
                            hintStyle: TextStyle(color: Colors.black26),
                          ),
                        ),
                      ),
                      _buildLocationSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AppButton(
                    onPressed: isLoading ? null : _saveTransaction,
                    isLoading: isLoading,
                    icon: Icons.save_outlined,
                    label: isEditMode ? 'Update Transaksi' : 'Simpan Transaksi',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
