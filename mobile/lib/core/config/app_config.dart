class AppConfig {
  static const String appName = 'Poketto';

  // Lowest-priority fallback. Dashboard prefers backend/user settings first.
  static final double dailyBudget = double.tryParse(
        const String.fromEnvironment('DAILY_BUDGET', defaultValue: '0'),
      ) ??
      0;
}
