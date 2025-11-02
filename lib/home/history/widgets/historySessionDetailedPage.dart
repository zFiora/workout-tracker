// home/history/history_session_detail_page.dart
import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistorySessionDetailPage extends StatelessWidget {
  final WorkoutHistoryEntry entry;
  const HistorySessionDetailPage({super.key, required this.entry});

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _durationLabel(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return MyCustomeScaffoldView(
      title: entry.templateName,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              const Icon(Icons.timer, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_fmtTime(entry.startedAt)} → ${_fmtTime(entry.endedAt)}  •  ${_durationLabel(entry.duration)}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),

          // Exercises
          ...entry.logs.map((log) {
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        log.exerciseName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Image.asset(log.exerciseIcon, width: 24, height: 24),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...List.generate(log.sets.length, (i) {
                    final s = log.sets[i];
                    final typeLabel = s.type.name;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        '${i + 1}.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      title: Text('${s.weight} kg × ${s.reps} reps'),
                      subtitle: Text('${s.timestamp} • $typeLabel'),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
