import 'package:flutter/material.dart';
import 'package:workout_tracker/common/formatters/dateTimeFormatter.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/history/exDetail/exDetailPage.dart';
import 'package:workout_tracker/home/history/repos/PREventRepository.dart';
import 'package:workout_tracker/home/history/utils/historyEnteryStats.dart';
import 'package:workout_tracker/home/history/widgets/historyExcersiceCard.dart';
import 'package:workout_tracker/home/history/widgets/historyHeaderCard.dart';
import 'package:workout_tracker/home/history/widgets/historyInfoChip.dart';
import 'package:workout_tracker/home/history/widgets/historySetRow.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistorySessionDetailPage extends StatelessWidget {
  final WorkoutHistoryEntry entry;

  /// Must be the Hive key from historyBox for this entry.
  final dynamic historyKey;

  const HistorySessionDetailPage({
    super.key,
    required this.entry,
    required this.historyKey,
  });

  String _setTypeShort(SetType t) {
    switch (t) {
      case SetType.work:
        return 'W';
      case SetType.warmup:
        return 'WU';
      case SetType.dropset:
        return 'DS';
    }
  }

  Color _badgeBg(ColorScheme cs, SetType t) {
    switch (t) {
      case SetType.work:
        return cs.primaryContainer;
      case SetType.warmup:
        return cs.tertiaryContainer;
      case SetType.dropset:
        return cs.secondaryContainer;
    }
  }

  Color _badgeFg(ColorScheme cs, SetType t) {
    switch (t) {
      case SetType.work:
        return cs.onPrimaryContainer;
      case SetType.warmup:
        return cs.onTertiaryContainer;
      case SetType.dropset:
        return cs.onSecondaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final day = dayLabel(entry.endedAt);
    final timeLine = '${fmtTime(entry.startedAt)} – ${fmtTime(entry.endedAt)}';
    final duration = durationLabel(entry.duration);

    final stats = computeHistoryEntryStats(entry);

    final prRepo = PrEventsRepository();

    return FutureBuilder<Set<String>>(
      future: prRepo.loadBestWeightPrKeys(historyKey),
      builder: (context, snap) {
        final prKeys = snap.data ?? <String>{};

        return MyCustomeScaffoldView(
          title: entry.templateName,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              HistoryHeaderCard(
                iconPath: entry.templateIcon,
                title: entry.templateName,
                subtitle: '$day • $timeLine • $duration',
                chips: [
                  HistoryInfoChip(
                    icon: Icons.list_alt_outlined,
                    label: '${stats.exerciseCount} exercises',
                  ),
                  HistoryInfoChip(
                    icon: Icons.repeat,
                    label: '${stats.setCount} sets',
                  ),
                  HistoryInfoChip(
                    icon: Icons.scale_outlined,
                    label: '${formatVolumeKg(stats.volume)} kg',
                  ),
                  if (snap.connectionState == ConnectionState.waiting)
                    const HistoryInfoChip(
                      icon: Icons.star_outline,
                      label: 'Loading PR…',
                    )
                  else if (prKeys.isNotEmpty)
                    HistoryInfoChip(
                      icon: Icons.emoji_events_outlined,
                      label: '${prKeys.length} PR',
                    ),
                ],
              ),
              const SizedBox(height: 14),

              ...entry.logs.map((log) {
                // Keep it safe. If exerciseId isn't an int, disable navigation.
                final dynamic rawId = (log as dynamic).exerciseId;
                final int? exId = rawId is int ? rawId : null;

                return HistoryExerciseCard(
                  exerciseName: log.exerciseName,
                  exerciseIcon: log.exerciseIcon,
                  onTap: exId == null
                      ? () {}
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExerciseDetailPage(
                                exerciseId: exId,
                                exerciseName: log.exerciseName,
                              ),
                            ),
                          );
                        },
                  child: Column(
                    children: List.generate(log.sets.length, (i) {
                      final s = log.sets[i];

                      final label = (s.type == SetType.warmup)
                          ? 'WU ${i + 1}'
                          : 'Set ${i + 1}';

                      final isPr = (exId == null)
                          ? false
                          : prRepo.isPr(prKeys, exId, s.timestamp);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: HistorySetRow(
                          leftLabel: label,
                          badgeText: _setTypeShort(s.type),
                          badgeBg: _badgeBg(cs, s.type),
                          badgeFg: _badgeFg(cs, s.type),
                          mainText: '${s.weight} kg × ${s.reps}',
                          subText: fmtTime(s.timestamp),
                          showPr: isPr,
                        ),
                      );
                    }),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
