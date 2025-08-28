import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/history_page/historyViewModel.dart';
import 'package:workout_tracker/home/history_page/widgets/historySessionDetailedPage.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  String _formatDate(DateTime dt) {
    // e.g., 2025-08-28 21:05
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    final items = vm.history;

    if (items.isEmpty) {
      return const Center(child: Text('No old sessions'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final WorkoutHistoryEntry e = items[i];
        return ListTile(
          title: Text(e.templateName),
          subtitle: Text(
            '${_formatDate(e.startedAt)} → ${_formatDate(e.endedAt)} • ${_formatDuration(e.duration)}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await vm.deleteAt(i);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleted from history')),
                );
              }
            },
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HistorySessionDetailPage(entry: e),
              ),
            );
          },
        );
      },
    );
  }
}
