import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poketto/main.dart';
import 'package:poketto/onboarding_screen.dart';
import 'package:poketto/providers/theme_controller.dart';
import 'package:poketto/providers/user_provider.dart';
import 'package:poketto/ui/app_theme.dart';

void main() {
  testWidgets('shows Poketto login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Masuk ke Poketto'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-submit')), findsOneWidget);
  });

  testWidgets('register remains usable on a small keyboard-sized viewport',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    expect(find.text('Mulai bersama Poketto'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('register-submit')));
    expect(find.byKey(const ValueKey('register-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('premium onboarding keeps three-page navigation intact',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const OnboardingScreen(),
        routes: {'/login': (_) => const LoginScreen()},
      ),
    );

    expect(find.text('Catat tanpa ribet'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Budget tetap terkendali'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Pahami pola uangmu'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);
  });

  testWidgets('theme controller switches MaterialApp immediately',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: Consumer<ThemeController>(
          builder: (context, themeController, _) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.themeMode,
            home: const Scaffold(body: Text('Poketto theme test')),
          ),
        ),
      ),
    );

    expect(Theme.of(tester.element(find.text('Poketto theme test'))).brightness,
        Brightness.light);

    await controller.setDarkMode(true);
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(find.text('Poketto theme test'))).brightness,
        Brightness.dark);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(ThemeController.preferenceKey), 'dark');
  });
}
