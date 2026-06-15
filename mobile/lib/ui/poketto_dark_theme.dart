import 'package:flutter/material.dart';

class PokettoDarkColors {
  static const orange = Color(0xFFFF8C42);
  static const background = Color(0xFF07070B);
  static const surface = Color(0xFF111119);
  static const surfaceSoft = Color(0xFF181824);
  static const text = Colors.white;
  static const secondaryText = Color(0xFF9CA3AF);
  static const border = Color(0xFF242433);
  static const green = Color(0xFF34D399);
  static const red = Color(0xFFFB7185);
}

class PokettoDarkTheme {
  static const fontFamily = 'Plus Jakarta Sans';

  static ThemeData get theme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: PokettoDarkColors.background,
      primaryColor: PokettoDarkColors.orange,
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: PokettoDarkColors.text,
        displayColor: PokettoDarkColors.text,
      ),
      colorScheme: const ColorScheme.dark(
        primary: PokettoDarkColors.orange,
        secondary: PokettoDarkColors.orange,
        surface: PokettoDarkColors.surface,
        background: PokettoDarkColors.background,
        onPrimary: Colors.white,
        onSurface: PokettoDarkColors.text,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: PokettoDarkColors.background,
        foregroundColor: PokettoDarkColors.text,
      ),
      cardTheme: CardThemeData(
        color: PokettoDarkColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PokettoDarkColors.surface,
        hintStyle: const TextStyle(color: PokettoDarkColors.secondaryText),
        labelStyle: const TextStyle(color: PokettoDarkColors.secondaryText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: PokettoDarkColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: PokettoDarkColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: PokettoDarkColors.orange, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PokettoDarkColors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
