import 'package:flutter/material.dart';

enum SnackbarType { normal, success, warning }

class Mycustomsnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackbarType type = SnackbarType.normal,
  }) {
    final bgColor = _getColor(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: bgColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  static Color _getColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Colors.green;
      case SnackbarType.warning:
        return Colors.red;
      case SnackbarType.normal:
        return Colors.grey[800]!;
    }
  }
}
