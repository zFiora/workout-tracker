import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/history/ViewModel/historyViewModel.dart';
import 'package:workout_tracker/home/history/pages/historySessionDetailedPage.dart';
import 'package:workout_tracker/home/history/widgets/historyTile.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    final items = vm.historyItems;

    if (items.isEmpty) {
      return MyCustomeScaffoldView(
        title: 'History',
        body: _EmptyHistoryState(),
      );
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
            confirmDismiss: (_) async => true,
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
                      historyService: vm.service,
                    ),
                  ),
                );
              },
              onDelete: deleteWithUndo,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 40,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No workouts yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first session to\nsee your history here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
