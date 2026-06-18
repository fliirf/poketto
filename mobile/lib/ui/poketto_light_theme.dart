import 'package:flutter/material.dart';
import 'package:poketto/ui/app_theme.dart';

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

  static ThemeData get theme => AppTheme.light;
}

class PokettoGradientScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;

  const PokettoGradientScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF161311),
                  Color(0xFF0F0F0F),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF9F5),
                  Color(0xFFFFF1E7),
                  Color(0xFFFFE6D5),
                ],
              ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        bottomNavigationBar: bottomNavigationBar,
        body: body,
      ),
    );
  }
}
