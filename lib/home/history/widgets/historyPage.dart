import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
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
      return const MyCustomeScaffoldView(
        title: 'History',
        body: EmptyState(
          icon: Icons.history_rounded,
          title: 'No workouts yet',
          message: 'Finish your first session and it will\nshow up here with all its stats.',
        ),
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                color: Theme.of(context)
                    .colorScheme
                    .error
                    .withValues(alpha: 0.16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onDismissed: (_) => deleteWithUndo(),
            child: FadeRiseIn(
              index: i,
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
            ),
          );
        },
      ),
    );
  }
}
