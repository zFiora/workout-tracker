import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/formatters/dateTimeFormatter.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/home/account/model/profileStats.dart';
import 'package:workout_tracker/home/history/ViewModel/historyViewModel.dart';

/// A grid of real, computed workout statistics. Everything here is derived
/// from the user's actual local history (via [HistoryViewModel]) or the
/// server-owned streak passed in — nothing is fabricated.
class ProfileStatsGrid extends StatelessWidget {
  const ProfileStatsGrid({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
  });

  final int currentStreak;
  final int bestStreak;

  static String _compactVolume(double kg) {
    if (kg >= 1000000) return '${(kg / 1000000).toStringAsFixed(1)}M';
    if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(1)}k';
    return kg.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryViewModel>().history;
    final stats = ProfileStats.from(history);

    final tiles = <Widget>[
      _StatTile(
        icon: Icons.fitness_center_rounded,
        value: '${stats.workouts}',
        label: 'Workouts',
      ),
      _StatTile(
        icon: Icons.local_fire_department_rounded,
        value: '$currentStreak',
        label: 'Day streak',
        accent: context.tokens.warning,
      ),
      _StatTile(
        icon: Icons.timer_outlined,
        value: stats.totalTime == Duration.zero
            ? '—'
            : durationLabel(stats.totalTime),
        label: 'Total time',
      ),
      _StatTile(
        icon: Icons.monitor_weight_outlined,
        value: stats.totalVolumeKg <= 0
            ? '—'
            : '${_compactVolume(stats.totalVolumeKg)} kg',
        label: 'Volume lifted',
      ),
      _StatTile(
        icon: Icons.list_alt_rounded,
        value: '${stats.exercisesTracked}',
        label: 'Exercises',
      ),
      _StatTile(
        icon: Icons.emoji_events_outlined,
        value: '$bestStreak',
        label: 'Best streak',
        accent: context.tokens.success,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.98,
        children: tiles,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tint = accent ?? cs.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.tokens.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: tint, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
