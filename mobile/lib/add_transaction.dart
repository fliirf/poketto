import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/data/repositories/app_repositories.dart';
import 'package:poketto/data/services/location_service.dart';
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

  bool get isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
            selectedCategoryId = readInt(incomeCategories.first['category_id']);
          } else if (!isIncome && expenseCategories.isNotEmpty) {
            selectedCategoryId =
                readInt(expenseCategories.first['category_id']);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, 'Kategori belum bisa dimuat. Coba lagi.');
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
        final transactionId = readInt(widget.transaction!['transaction_id']);
        if (transactionId == null) {
          throw const FormatException('ID transaksi tidak valid');
        }
        result = await AppRepositories.transactions.updateTransaction(
          transactionId: transactionId,
          categoryId: selectedCategoryId!,
          type: isIncome ? 'income' : 'expense',
          amount: amount,
          description: description,
          transactionDate: selectedDate,
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
      final transactionId = readInt(widget.transaction!['transaction_id']);
      if (transactionId == null) {
        throw const FormatException('ID transaksi tidak valid');
      }

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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.poketto.border),
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
                secondary: Icon(
                  _attachLocation
                      ? Icons.location_on_outlined
                      : Icons.location_off_outlined,
                  color: Theme.of(context).colorScheme.primary,
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
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                Text(
                  'Lat: ${_locationLat!.toStringAsFixed(6)}',
                  style:
                      TextStyle(fontSize: 12, color: context.poketto.mutedText),
                ),
                Text(
                  'Lng: ${_locationLng!.toStringAsFixed(6)}',
                  style:
                      TextStyle(fontSize: 12, color: context.poketto.mutedText),
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
          color: Theme.of(context).colorScheme.onSurface,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.poketto.border),
      ),
      child: Row(
        crossAxisAlignment: minHeight > 70
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: minHeight > 70 ? 14 : 0),
            child: Icon(icon,
                color: Theme.of(context).colorScheme.primary, size: 21),
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
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active ? Colors.white : context.poketto.mutedText,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : context.poketto.mutedText,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.poketto.border),
        boxShadow: [
          BoxShadow(
            color: context.poketto.shadow,
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
                      readInt(incomeCategories.first['category_id']);
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
                      readInt(expenseCategories.first['category_id']);
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      color: Theme.of(context).colorScheme.primary,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        shape: const CircleBorder(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi',
                        style: AppTextStyles.title.copyWith(
                            color: Theme.of(context).colorScheme.onSurface),
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
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            hintText: 'Rp 0',
                            hintStyle: TextStyle(
                              color: context.poketto.mutedText,
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
                                  ? Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 17),
                                      child: Text(
                                        'Belum ada kategori...',
                                        style: TextStyle(
                                          color: context.poketto.mutedText,
                                        ),
                                      ),
                                    )
                                  : DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<int>(
                                        value: selectedCategoryId,
                                        isExpanded: true,
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: context.poketto.mutedText,
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
                                            value: readInt(
                                                    category['category_id']) ??
                                                0,
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
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _formLabel('Tanggal'),
                                InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                      initialDate: selectedDate,
                                    );
                                    if (picked != null) {
                                      setState(() => selectedDate = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                            selectedDate.hour,
                                            selectedDate.minute,
                                          ));
                                    }
                                  },
                                  child: _fieldShell(
                                    icon: Icons.calendar_today_outlined,
                                    child: Text(
                                      DateFormat('d MMM yyyy')
                                          .format(selectedDate),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _formLabel('Waktu'),
                                InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          TimeOfDay.fromDateTime(selectedDate),
                                    );
                                    if (picked != null) {
                                      setState(() => selectedDate = DateTime(
                                            selectedDate.year,
                                            selectedDate.month,
                                            selectedDate.day,
                                            picked.hour,
                                            picked.minute,
                                          ));
                                    }
                                  },
                                  child: _fieldShell(
                                    icon: Icons.schedule_rounded,
                                    child: Text(
                                      DateFormat('HH:mm').format(selectedDate),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'Contoh: Makan siang',
                            hintStyle:
                                TextStyle(color: context.poketto.mutedText),
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: AppButton(
                    outlined: true,
                    onPressed:
                        isLoading ? null : () => Navigator.pop(context, false),
                    label: 'Batal',
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
