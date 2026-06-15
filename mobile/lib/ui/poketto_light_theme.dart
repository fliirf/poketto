import 'package:flutter/material.dart';

class PokettoLightColors {
  static const primary = Color(0xFFFF8C42);
  static const balanceStart = Color(0xFFFF8C42);
  static const balanceMid = Color(0xFFFFB26B);
  static const balanceEnd = Color(0xFFE96F1F);
  static const backgroundStart = Color(0xFFFFEEDD);
  static const backgroundMid = Color(0xFFFFF8F0);
  static const backgroundEnd = Colors.white;
  static const surface = Colors.white;
  static const surfaceWarm = Color(0xFFFFF8F0);
  static const border = Color(0xFFFFD7B8);
  static const text = Color(0xFF1F1A17);
  static const secondaryText = Color(0xFF7C6F66);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFE64545);
}

class PokettoLightTheme {
  static const fontFamily = 'Plus Jakarta Sans';

  static ThemeData get theme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: PokettoLightColors.backgroundMid,
      primaryColor: PokettoLightColors.primary,
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: PokettoLightColors.text,
        displayColor: PokettoLightColors.text,
      ),
      colorScheme: const ColorScheme.light(
        primary: PokettoLightColors.primary,
        secondary: PokettoLightColors.primary,
        surface: PokettoLightColors.surface,
        background: PokettoLightColors.backgroundMid,
        onPrimary: Colors.white,
        onSurface: PokettoLightColors.text,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: PokettoLightColors.text,
      ),
      cardTheme: CardThemeData(
        color: PokettoLightColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: PokettoLightColors.secondaryText),
        labelStyle: const TextStyle(color: PokettoLightColors.secondaryText),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: PokettoLightColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: PokettoLightColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:
              const BorderSide(color: PokettoLightColors.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PokettoLightColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class PokettoGradientScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;

  const PokettoGradientScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: PokettoLightColors.backgroundMid,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              PokettoLightColors.backgroundStart,
              PokettoLightColors.backgroundMid,
              PokettoLightColors.backgroundEnd,
            ],
          ),
        ),
        child: body,
      ),
    );
  }
}
