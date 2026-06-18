import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const preferenceKey = 'poketto_theme_mode';

  ThemeMode _themeMode;

  ThemeController({ThemeMode initialMode = ThemeMode.light})
      : _themeMode = initialMode;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static Future<ThemeController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(preferenceKey);
    return ThemeController(
      initialMode: savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> setDarkMode(bool enabled) async {
    final nextMode = enabled ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == nextMode) return;
    _themeMode = nextMode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      preferenceKey,
      enabled ? 'dark' : 'light',
    );
  }
}
