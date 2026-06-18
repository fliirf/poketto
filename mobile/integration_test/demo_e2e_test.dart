import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:poketto/data/repositories/app_repositories.dart';
import 'package:poketto/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Demo Test on Poketto', (WidgetTester tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('poketto_onboarding_completed');
    await preferences.remove('userId');
    await AppRepositories.tokenStorage.clearToken();

    // 1. Start the app
    await app.main();
    await tester.pumpAndSettle();

    // Wait for launch splash screen to finish (2 seconds delay)
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify we are on the onboarding screen
    expect(find.text('Catat tanpa ribet'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);

    // Tap Lewati
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify we are on the login screen
    expect(find.text('POKETTO'), findsWidgets);
    expect(find.text('Masuk ke Poketto'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-submit')), findsOneWidget);

    // 2. Navigate to Sign Up / Register page
    final signUpBtn = find.text('Daftar');
    expect(signUpBtn, findsOneWidget);
    await tester.tap(signUpBtn);
    await tester.pumpAndSettle();

    // Verify we are on the Register page
    expect(find.text('Mulai bersama Poketto'), findsOneWidget);

    // 3. Fill registration details with prefix E2E_
    final nameField = find.byKey(const ValueKey('register-name'));
    final emailField = find.byKey(const ValueKey('register-email'));
    final passwordField = find.byKey(const ValueKey('register-password'));
    final confirmPasswordField =
        find.byKey(const ValueKey('register-confirm-password'));

    final uniqueTime = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'E2E_user_$uniqueTime@example.com';
    const testPassword = 'Password123!';

    await tester.enterText(nameField, 'E2E User $uniqueTime');
    await tester.enterText(emailField, testEmail);
    await tester.enterText(passwordField, testPassword);
    await tester.enterText(confirmPasswordField, testPassword);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // 4. Click Daftar and wait for register to finish and redirect to Home
    final daftarBtn = find.byKey(const ValueKey('register-submit'));
    await tester.ensureVisible(daftarBtn);
    await tester.pumpAndSettle();
    final registerButton = tester.widget<ElevatedButton>(daftarBtn);
    expect(registerButton.onPressed, isNotNull);
    registerButton.onPressed!.call();

    // Render may cold-start. Poll the actual destination instead of assuming
    // that starting the request means the register flow passed.
    for (var attempt = 0;
        attempt < 24 && find.byIcon(Icons.home_rounded).evaluate().isEmpty;
        attempt++) {
      await tester.pump(const Duration(seconds: 5));
    }

    // Verify we successfully logged in and Dashboard loads
    if (find.byIcon(Icons.home_rounded).evaluate().isEmpty) {
      final texts = find
          .byType(Text)
          .evaluate()
          .map((element) => (element.widget as Text).data ?? '')
          .where((text) => text.isNotEmpty)
          .toList();
      print('=== E2E REGISTER FAILURE SCREEN TEXTS: $texts ===');
    }
    expect(find.byIcon(Icons.home_rounded), findsWidgets);
    expect(find.text('Halo, E2E User $uniqueTime'), findsWidgets);

    // Dashboard contract sections must exist even for a new/empty account.
    expect(find.text('Daily budget'), findsOneWidget);
    expect(find.text('Monthly budget'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Komposisi pengeluaran'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Komposisi pengeluaran'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tren pengeluaran'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tren pengeluaran'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Currency converter'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Currency converter'), findsOneWidget);

    final swapButton = find.byKey(const ValueKey('converter-swap'));
    expect(swapButton, findsOneWidget);
    final resultBeforeSwap = (tester.widget<Text>(
      find.byKey(const ValueKey('converter-result')),
    )).data;
    await tester.tap(swapButton);
    await tester.pumpAndSettle();
    final resultAfterSwap = (tester.widget<Text>(
      find.byKey(const ValueKey('converter-result')),
    )).data;
    expect(resultAfterSwap, isNot(resultBeforeSwap));

    await tester.scrollUntilVisible(
      find.byIcon(Icons.notifications_outlined),
      -500,
      scrollable: find.byType(Scrollable).first,
    );

    // Tap Notification Bell Icon to open panel
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify Notification Center panel title is visible
    expect(find.text('Notification Center'), findsWidgets);

    // Tap outside bottom sheet to close it
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 5. Test adding a transaction
    await tester.tap(find.text('Tambah transaksi'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), '15000'); // Amount
    await tester.enterText(
        textFields.at(1), 'E2E_Test Lunch'); // Description/Note
    await tester.pumpAndSettle();

    // Tap Simpan
    await tester.tap(find.text('Simpan Transaksi'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 6. Navigate to Riwayat to verify transaction
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    if (find.text('E2E_Test Lunch').evaluate().isEmpty) {
      final texts = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '')
          .toList();
      print('=== E2E FAILURE RIWAYAT SCREEN TEXTS: $texts ===');
    }
    expect(find.text('E2E_Test Lunch'), findsWidgets);

    // 7. Navigate to Kategori
    await tester.tap(find.text('Kategori'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Kelola Kategori'), findsWidgets);

    // 8. Navigate to Settings
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Pengaturan'), findsWidgets);
    expect(find.text('Smart Notifications'), findsNothing);
    expect(
      find.textContaining('Peringatan budget aktif secara default'),
      findsOneWidget,
    );

    // 9. Clean up only the transaction created by this test.
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final createdTransaction = find.text('E2E_Test Lunch');
    expect(createdTransaction, findsWidgets);
    await tester.tap(createdTransaction.first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 10. Go back to Home and Logout
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Open profile menu using new person icon
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Tap Logout
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Verify back on Login page
    expect(find.text('POKETTO'), findsWidgets);
    expect(find.text('Masuk ke Poketto'), findsOneWidget);
  });
}
