import 'package:flutter/material.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/support/services/bug_report_api_service.dart';

/// The three failure modes the bug-report screens present differently.
enum BugReportErrorKind { offline, sessionExpired, server }

extension BugReportErrorKindX on BugReportErrorKind {
  static BugReportErrorKind fromError(Object error) {
    if (error is! BugReportApiException) return BugReportErrorKind.server;
    return switch (error.reason) {
      NetworkReason.noConnection || NetworkReason.timeout => BugReportErrorKind.offline,
      NetworkReason.unauthorized => BugReportErrorKind.sessionExpired,
      NetworkReason.serverError ||
      NetworkReason.requestFailed ||
      NetworkReason.unknown =>
        BugReportErrorKind.server,
    };
  }

  // Same icons the Account page uses for the equivalent states
  // (wifi_off = unreachable, cloud_off = server trouble, lock = auth).
  IconData get icon => switch (this) {
        BugReportErrorKind.offline => Icons.wifi_off_rounded,
        BugReportErrorKind.sessionExpired => Icons.lock_outline,
        BugReportErrorKind.server => Icons.cloud_off_rounded,
      };

  String get title => switch (this) {
        BugReportErrorKind.offline => 'No connection',
        BugReportErrorKind.sessionExpired => 'Session expired',
        BugReportErrorKind.server => 'Something went wrong',
      };
}

/// Full-page error state with a kind-specific icon/title, the server's
/// message, and a Retry button.
class BugReportErrorView extends StatelessWidget {
  const BugReportErrorView({
    super.key,
    required this.kind,
    required this.message,
    required this.onRetry,
  });

  final BugReportErrorKind kind;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(kind.icon, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(kind.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
