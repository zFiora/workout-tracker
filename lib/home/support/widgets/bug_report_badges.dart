import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/support/models/bug_report.dart';

/// Small colored pill for a bug report's status, reusing the app's existing
/// [StatPill] primitive rather than introducing a new badge design.
class BugReportStatusChip extends StatelessWidget {
  const BugReportStatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final parsed = BugReportStatusParsing.parse(status);
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final color = switch (parsed) {
      BugReportStatus.open => cs.primary,
      BugReportStatus.inProgress => tokens.warning,
      BugReportStatus.resolved => tokens.success,
      BugReportStatus.closed => cs.onSurfaceVariant,
      BugReportStatus.unknown => cs.onSurfaceVariant,
    };
    return StatPill(label: parsed.label, color: color, filled: true);
  }
}

/// Priority is display-only — the user never sets or changes it (see
/// `BugReportApiService` doc comment).
class BugReportPriorityChip extends StatelessWidget {
  const BugReportPriorityChip({super.key, required this.priority});
  final String priority;

  @override
  Widget build(BuildContext context) {
    final parsed = BugReportPriorityParsing.parse(priority);
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final color = switch (parsed) {
      BugReportPriority.low => cs.onSurfaceVariant,
      BugReportPriority.medium => cs.primary,
      BugReportPriority.high => tokens.warning,
      BugReportPriority.critical => cs.error,
      BugReportPriority.unknown => cs.onSurfaceVariant,
    };
    return StatPill(label: parsed.label, icon: Icons.flag_rounded, color: color);
  }
}
