import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_view.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';
import 'package:workout_tracker/home/session/recap/workout_recap.dart';

/// Entry point from a History workout into its saved summary. Only shown for
/// workouts that have a [WorkoutRecap]; older workouts don't get one.
class HistoryRecapCard extends StatelessWidget {
  const HistoryRecapCard({
    super.key,
    required this.recap,
    required this.onOpen,
  });

  final WorkoutRecap recap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final summary = recap.summary;
    final primary = [
      for (final m in Muscle.values)
        if (summary.primary.contains(m)) m.displayName,
    ];
    final subtitle = [
      if (primary.isNotEmpty)
        primary.take(3).join(' · ') +
            (primary.length > 3 ? ' +${primary.length - 3}' : ''),
      if (recap.hasPhoto) 'Progress photo',
    ].join('  •  ');

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: IgnorePointer(
              child: MuscleMapView(
                primary: summary.primary,
                secondary: summary.secondary,
                backgroundColor: cs.surfaceContainer,
                showLabels: false,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Muscle summary', style: theme.textTheme.titleSmall),
                    if (recap.hasPhoto) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.photo_outlined, size: 16, color: cs.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.isEmpty ? 'View muscles worked' : subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
