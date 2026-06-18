import 'package:flutter/material.dart';
import 'package:poketto/ui/app_theme.dart';

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

  static ThemeData get theme => AppTheme.dark;
}
