import 'package:flutter/material.dart';

class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message, backgroundColor: Colors.green);
  }

  static void error(BuildContext context, String message) {
    show(context, message, backgroundColor: Colors.red);
  }

  static void warning(BuildContext context, String message) {
    show(context, message, backgroundColor: Colors.orange);
  }
}
