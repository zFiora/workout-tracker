import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/history/historyViewModel.dart';
import 'package:workout_tracker/home/history/widgets/historySessionDetailedPage.dart';
import 'package:workout_tracker/home/history/widgets/historyTile.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    final items = vm.history;

    if (items.isEmpty) {
      return const Center(child: Text('No old sessions'));
    }

    return MyCustomeScaffoldView(
      title: 'History',
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final e = items[i];
          return HistoryTile(
            entry: e,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HistorySessionDetailPage(entry: e),
                ),
              );
            },
            onDelete: () async {
              await vm.deleteAt(i);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleted from history')),
                );
              }
            },
          );
        },
      ),
    );
  }
}
