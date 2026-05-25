import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/data/models/budget_alert_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _channelId = 'poketto_budget_alerts';
  static const String _channelName = 'Budget Alerts';
  static const String _channelDescription =
      'Notifikasi peringatan budget dan kesehatan finansial Poketto.';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      );

      await _notifications.initialize(settings: settings);

      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();

      _initialized = true;
    } catch (error) {
      debugPrint('Notification init error: $error');
    }
  }

  Future<void> showBudgetAlerts(List<BudgetAlertModel> alerts) async {
    if (alerts.isEmpty) return;

    try {
      await initialize();
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (final alert in alerts) {
        final key = 'notified_${today}_${alert.alertType}_${alert.message}';
        if (prefs.getBool(key) == true) continue;

        await _notifications.show(
          id: key.hashCode & 0x7fffffff,
          title: _titleForAlert(alert),
          body: alert.message,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
        );
        await prefs.setBool(key, true);
      }
    } catch (error) {
      debugPrint('Notification error: $error');
    }
  }

  Future<void> checkBudgetUsage({
    required int userId,
    required double warningThreshold,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> categories,
    double? dailyLimit,
  }) async {
    try {
      await initialize();

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final month = DateFormat('yyyy-MM').format(now);
      final dailyExpense = _sumTransactions(
        transactions,
        datePrefix: today,
      );

      if (dailyLimit != null && dailyLimit > 0) {
        final warningAmount = dailyLimit * (warningThreshold / 100);
        if (dailyExpense >= dailyLimit) {
          await _showOnce(
            prefs: prefs,
            key: 'budget_usage_${userId}_${today}_daily_exceeded',
            title: 'Limit harian terlampaui',
            body:
                'Pengeluaran hari ini sudah ${_formatCurrency(dailyExpense)}, melewati limit ${_formatCurrency(dailyLimit)}.',
          );
        } else if (dailyExpense >= warningAmount) {
          await _showOnce(
            prefs: prefs,
            key: 'budget_usage_${userId}_${today}_daily_warning',
            title: 'Pengeluaran harian mendekati limit',
            body:
                'Kamu sudah memakai ${_formatCurrency(dailyExpense)} dari limit harian ${_formatCurrency(dailyLimit)}.',
          );
        }
      }

      for (final category in categories) {
        final categoryId = readInt(category['category_id'] ?? category['id']);
        final categoryName = readString(category['name']) ?? 'Kategori';
        final limit = readDouble(category['monthly_budget']);
        if (categoryId == null || limit == null || limit <= 0) continue;

        final spent = _sumTransactions(
          transactions,
          datePrefix: month,
          categoryId: categoryId,
        );
        final warningAmount = limit * (warningThreshold / 100);

        if (spent >= limit) {
          await _showOnce(
            prefs: prefs,
            key:
                'budget_usage_${userId}_${month}_category_${categoryId}_exceeded',
            title: 'Limit kategori terlampaui',
            body:
                'Kategori $categoryName sudah melewati limit ${_formatCurrency(limit)}.',
          );
        } else if (spent >= warningAmount) {
          await _showOnce(
            prefs: prefs,
            key:
                'budget_usage_${userId}_${month}_category_${categoryId}_warning',
            title: 'Kategori mendekati limit',
            body:
                'Kategori $categoryName sudah memakai ${_formatCurrency(spent)} dari limit ${_formatCurrency(limit)}.',
          );
        }
      }
    } catch (error) {
      debugPrint('Budget usage notification error: $error');
    }
  }

  double _sumTransactions(
    List<Map<String, dynamic>> transactions, {
    required String datePrefix,
    int? categoryId,
  }) {
    double total = 0;

    for (final transaction in transactions) {
      final type = readString(
        transaction['category_type'] ?? transaction['type'],
      );
      if (type != 'expense') continue;

      final transactionCategoryId = readInt(transaction['category_id']);
      if (categoryId != null && transactionCategoryId != categoryId) continue;

      final rawDate = readString(
        transaction['transaction_date'] ?? transaction['date'],
      );
      if (rawDate == null || !rawDate.startsWith(datePrefix)) continue;

      total += readDouble(transaction['amount']) ?? 0;
    }

    return total;
  }

  Future<void> _showOnce({
    required SharedPreferences prefs,
    required String key,
    required String title,
    required String body,
  }) async {
    if (prefs.getBool(key) == true) return;

    await _notifications.show(
      id: key.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
    );
    await prefs.setBool(key, true);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _titleForAlert(BudgetAlertModel alert) {
    if (alert.alertType.contains('daily_budget')) {
      return 'Budget harian habis';
    }
    if (alert.alertType.contains('category_budget')) {
      return 'Budget kategori hampir habis';
    }
    return 'Peringatan keuangan Poketto';
  }
}
