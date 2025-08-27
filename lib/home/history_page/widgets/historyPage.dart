import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/history_page/historyViewModel.dart';
import 'package:workout_tracker/home/history_page/widgets/historySessionDetailedPage.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  String _dateLabel(DateTime d) {
    // e.g., Tue, Aug 27
    return '${_weekday(d.weekday)}, ${_month(d.month)} ${d.day}';
  }

  static String _weekday(int w) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];

  static String _month(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  String _durationLabel(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryViewModel>(
      builder: (context, vm, _) {
        final grouped = vm.groupedByDay();

        return MyCustomeScaffoldView(
          title: 'History',
          body: grouped.isEmpty
              ? const _EmptyHistory()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: grouped.length,
                  itemBuilder: (context, i) {
                    final day = grouped.keys.elementAt(i);
                    final items = grouped[day]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            _dateLabel(day),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        ...items.map(
                          (e) => _HistoryTile(
                            entry: e,
                            volume: vm.totalVolume(e),
                            sets: vm.totalSets(e),
                            durationLabel: _durationLabel(e.duration),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No old sessions'),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final WorkoutHistoryEntry entry;
  final double volume;
  final int sets;
  final String durationLabel;

  const _HistoryTile({
    required this.entry,
    required this.volume,
    required this.sets,
    required this.durationLabel,
  });

  @override
  Widget build(BuildContext context) {
    // final time = TimeOfDay.fromDateTime(entry.startedAt).format(context);
    return ListTile(
      title: Text(entry.templateName),
      subtitle: Text('$sets sets • ${volume.toStringAsFixed(0)} kg·reps'),
      trailing: Text(durationLabel),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistorySessionDetailPage(entry: entry),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: CircleAvatar(child: Image.asset(entry.templateIcon)),
    );
  }
}
