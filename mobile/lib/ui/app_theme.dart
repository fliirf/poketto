import 'package:flutter/material.dart';

@immutable
class PokettoColors extends ThemeExtension<PokettoColors> {
  final Color income;
  final Color expense;
  final Color warning;
  final Color elevatedSurface;
  final Color softSurface;
  final Color border;
  final Color mutedText;
  final Color shadow;

  const PokettoColors({
    required this.income,
    required this.expense,
    required this.warning,
    required this.elevatedSurface,
    required this.softSurface,
    required this.border,
    required this.mutedText,
    required this.shadow,
  });

  static const light = PokettoColors(
    income: Color(0xFF10B981),
    expense: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    elevatedSurface: Color(0xFFFFFFFF),
    softSurface: Color(0xFFFFF4EA),
    border: Color(0xFFF0E5DB),
    mutedText: Color(0xFF7B8498),
    shadow: Color(0x1A6B3A16),
  );

  static const dark = PokettoColors(
    income: Color(0xFF34D399),
    expense: Color(0xFFFF4164),
    warning: Color(0xFFFFB020),
    elevatedSurface: Color(0xFF202020),
    softSurface: Color(0xFF24201D),
    border: Color(0xFF343434),
    mutedText: Color(0xFFA5A5A5),
    shadow: Color(0x99000000),
  );

  @override
  PokettoColors copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? elevatedSurface,
    Color? softSurface,
    Color? border,
    Color? mutedText,
    Color? shadow,
  }) {
    return PokettoColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      softSurface: softSurface ?? this.softSurface,
      border: border ?? this.border,
      mutedText: mutedText ?? this.mutedText,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  PokettoColors lerp(covariant PokettoColors? other, double t) {
    if (other == null) return this;
    return PokettoColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension PokettoThemeContext on BuildContext {
  PokettoColors get poketto =>
      Theme.of(this).extension<PokettoColors>() ?? PokettoColors.light;
}

class PokettoSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

class PokettoRadius {
  static const small = 12.0;
  static const medium = 16.0;
  static const large = 20.0;
  static const extraLarge = 28.0;
}

class AppColors {
  static const primary = Color(0xFFFF6B00);
  static const accent = primary;
  static const background = Color(0xFFFFF9F4);
  static const surface = Colors.white;
  static const surfaceSoft = Color(0xFFFFF1E7);
  static const text = Color(0xFF1B1B24);
  static const mutedText = Color(0xFF7B8498);
  static const inactive = Color(0xFF94A3B8);
  static const border = Color(0xFFF0E5DB);
  static const income = Color(0xFF10B981);
  static const expense = Color(0xFFEF4444);
  static const warningBg = Color(0xFFFFF5E8);
  static const warningBorder = Color(0xFFFFD6A8);
  static const shadow = Color(0xFF6B3A16);
}

class AppTextStyles {
  static const hero =
      TextStyle(fontSize: 32, height: 1.05, fontWeight: FontWeight.w900);
  static const title = TextStyle(fontSize: 22, fontWeight: FontWeight.w900);
  static const sectionTitle =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w900);
  static const cardTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w800);
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
  static const amount = TextStyle(fontSize: 30, fontWeight: FontWeight.w900);
  static const body = TextStyle(fontSize: 14, height: 1.45);
  static const caption =
      TextStyle(fontSize: 11.5, height: 1.35, fontWeight: FontWeight.w600);
}

class AppTheme {
  static const _orange = Color(0xFFFF6B00);

  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: const Color(0xFFFFFDF9),
        surface: Colors.white,
        onSurface: const Color(0xFF1B1B24),
        semantic: PokettoColors.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: const Color(0xFF0F0F0F),
        surface: const Color(0xFF181818),
        onSurface: const Color(0xFFF8F8F8),
        semantic: PokettoColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
    required PokettoColors semantic,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: _orange,
      onPrimary: Colors.white,
      secondary: _orange,
      onSecondary: Colors.white,
      error: semantic.expense,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Plus Jakarta Sans',
      extensions: <ThemeExtension<dynamic>>[semantic],
    );

    final roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: semantic.border),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: background,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PokettoRadius.large),
          side: BorderSide(color: semantic.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF101010) : Colors.white,
        hintStyle: TextStyle(color: semantic.mutedText),
        labelStyle: TextStyle(color: semantic.mutedText),
        prefixIconColor: _orange,
        suffixIconColor: semantic.mutedText,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: roundedBorder,
        enabledBorder: roundedBorder,
        focusedBorder: roundedBorder.copyWith(
          borderSide: const BorderSide(color: _orange, width: 1.5),
        ),
        errorBorder: roundedBorder.copyWith(
          borderSide: BorderSide(color: semantic.expense),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _orange.withOpacity(.45),
          elevation: 0,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PokettoRadius.medium)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size(48, 52),
          side: BorderSide(color: semantic.border),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PokettoRadius.medium)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: DividerThemeData(color: semantic.border, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: semantic.elevatedSurface,
        contentTextStyle: TextStyle(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: surface,
        indicatorColor: _orange,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : semantic.mutedText,
            )),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? _orange : null,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: _orange),
    );
  }
}
