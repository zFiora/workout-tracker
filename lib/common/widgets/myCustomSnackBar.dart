import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';

enum SnackbarType { normal, success, warning }

/// Themed feedback toast with a leading status icon and accent stripe.
class Mycustomsnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackbarType type = SnackbarType.normal,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    final (Color accent, IconData icon) = switch (type) {
      SnackbarType.success => (tokens.success, Icons.check_circle_rounded),
      SnackbarType.warning => (cs.error, Icons.error_rounded),
      SnackbarType.normal => (cs.primary, Icons.info_rounded),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          content: Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .snackBarTheme
                      .contentTextStyle
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
