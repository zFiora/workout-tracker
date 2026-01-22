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
    final items = vm.historyItems; // ✅ sorted newest-first + has Hive key

    if (items.isEmpty) {
      return const Center(child: Text('No old sessions'));
    }

    return MyCustomeScaffoldView(
      title: 'History',
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 0),
        itemBuilder: (context, i) {
          final item = items[i];
          final entry = item.entry;

          Future<void> deleteWithUndo() async {
            final deletedEntry = entry;

            await vm.deleteByKey(item.key);

            if (!context.mounted) return;

            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: const Text('Deleted from history'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () async {
                      await vm.save(deletedEntry);
                    },
                  ),
                ),
              );
          }

          return Dismissible(
            key: ValueKey(item.key),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              // Optional: prevent accidental deletes by requiring a swipe + release.
              // Returning true allows dismiss.
              return true;
            },
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.only(right: 18),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.errorContainer,
              ),
              child: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            onDismissed: (_) => deleteWithUndo(),
            child: HistoryTile(
              entry: entry,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistorySessionDetailPage(
                      entry: item.entry,
                      historyKey: item.key,
                    ),
                  ),
                );
              },
              onDelete: deleteWithUndo, // menu delete fallback
            ),
          );
        },
      ),
    );
  }
}
