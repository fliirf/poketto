import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
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
  bool _permissionRequested = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
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

      _initialized = true;
    } catch (error) {
      debugPrint('Notification init error: $error');
    }
  }

  Future<void> showBudgetAlerts(List<BudgetAlertModel> alerts) async {
    if (alerts.isEmpty) return;

    try {
      await initialize();
      await _requestPermissionWhenNeeded();
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

  Future<void> _requestPermissionWhenNeeded() async {
    if (_permissionRequested) return;
    _permissionRequested = true;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    final macosPlugin = _notifications.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    await macosPlugin?.requestPermissions(
        alert: true, badge: true, sound: true);
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
