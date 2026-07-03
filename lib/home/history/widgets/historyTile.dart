import 'package:flutter/material.dart';
import 'package:workout_tracker/common/formatters/dateTimeFormatter.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/history/utils/historyEnteryStats.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

/// A completed workout in the history feed: template icon, name, day chip
/// and a row of session stats.
class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
  });

  final WorkoutHistoryEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = context.tokens;

    final dayText = dayLabel(entry.endedAt);
    final timeText = '${fmtTime(entry.startedAt)} – ${fmtTime(entry.endedAt)}';

    final stats = computeHistoryEntryStats(entry);

    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          color: cs.surfaceContainer,
          border: Border.all(color: tokens.cardBorder),
          boxShadow: [
            BoxShadow(
              color: tokens.cardShadow,
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ── Leading icon ─────────────────────────────────
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      gradient: RadialGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.20),
                          cs.primary.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Image.asset(
                      entry.templateIcon,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.fitness_center_rounded,
                        size: 22,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Title + time ─────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.templateName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$dayText · $timeText',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Menu ─────────────────────────────────────────
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    onSelected: (v) {
                      switch (v) {
                        case 'delete':
                          onDelete?.call();
                          break;
                        case 'open':
                          onTap?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'open',
                        child: _MenuItem(
                          icon: Icons.open_in_new_rounded,
                          label: 'Open details',
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: _MenuItem(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          danger: true,
                        ),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Stats row ────────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatPill(
                    icon: Icons.timer_outlined,
                    label: durationLabel(entry.duration),
                    color: cs.primary,
                    filled: true,
                  ),
                  StatPill(
                    icon: Icons.list_alt_rounded,
                    label: '${stats.exerciseCount} ex',
                  ),
                  StatPill(
                    icon: Icons.repeat_rounded,
                    label: '${stats.setCount} sets',
                  ),
                  StatPill(
                    icon: Icons.scale_outlined,
                    label: '${formatVolumeKg(stats.volume)} kg',
                    color: tokens.success,
                    filled: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
