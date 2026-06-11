import 'package:flutter/material.dart';

class AppFeedback {
  const AppFeedback._();

  static void success(BuildContext context, String message) {
    _show(context, message, Colors.green);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Colors.red);
  }

  static void info(BuildContext context, String message, {Color? color}) {
    _show(context, message, color ?? Colors.blueGrey);
  }

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
