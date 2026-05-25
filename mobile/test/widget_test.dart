import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:poketto/main.dart';
import 'package:poketto/providers/user_provider.dart';

void main() {
  testWidgets('shows Poketto login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('POKETTO'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
