import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/formatters/duarationFormatter.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/history/ViewModel/historyViewModel.dart';
import 'package:workout_tracker/home/session/active_session_manager.dart';
import 'package:workout_tracker/home/session/sessionViewModel.dart';
import 'package:workout_tracker/home/session/widgets/exerciseSessionTile.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';

class StartSessionPage extends StatelessWidget {
  const StartSessionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ActiveSessionManager>();
    final session = manager.session;

    if (session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Provide the session VM to the subtree so ExerciseSessionTile can read it.
    return ChangeNotifierProvider.value(
      value: session,
      child: _SessionBody(manager: manager),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SessionBody extends StatelessWidget {
  const _SessionBody({required this.manager});
  final ActiveSessionManager manager;

  // ── dialogs / sheets ────────────────────────────────────────────────────

  Future<bool> _confirmEndSession(BuildContext context) async {
    return (await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('End session?'),
            content: const Text('This will save your workout to history.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('End & Save'),
              ),
            ],
          ),
        )) ??
        false;
  }

  Future<bool?> _confirmDiscard(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard session?'),
        content: const Text(
          'All sets logged in this session will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _askSaveToTemplate(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save exercise changes?'),
        content: const Text(
          'You added or removed exercises during this session.\n\n'
          'Do you want to save these changes permanently to the template?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Just this session'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save to template'),
          ),
        ],
      ),
    );
  }

  void _showMinimizeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final cs = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'What do you want to do?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Continue
              _SheetOption(
                icon: Icons.play_circle_outline_rounded,
                label: 'Continue session',
                onTap: () => Navigator.pop(sheetCtx),
              ),
              // Minimize
              _SheetOption(
                icon: Icons.minimize_rounded,
                label: 'Minimize — keep running',
                subtitle: 'Session continues in background',
                onTap: () {
                  Navigator.pop(sheetCtx); // close sheet
                  Navigator.of(context).pop(); // pop session page
                },
              ),
              // End & Save
              _SheetOption(
                icon: Icons.save_rounded,
                label: 'End & Save',
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _endAndSaveSession(context);
                },
              ),
              // Discard
              _SheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Discard session',
                color: cs.error,
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final ok = await _confirmDiscard(context);
                  if (ok == true && context.mounted) {
                    manager.discardSession();
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _endAndSaveSession(BuildContext context) async {
    final session = manager.session;
    if (session == null) return;

    final ok = await _confirmEndSession(context);
    if (!ok || !context.mounted) return;

    // Snapshot everything we need BEFORE ending the session
    final prEvents = session.prHits.values
        .map((h) => h.toJson())
        .toList(growable: false);

    final exercisesModified = manager.exercisesWereModified;
    final templateId = manager.templateId;
    final currentExerciseIds = manager.exercises.map((e) => e.id).toList();

    // End session — timer stops, manager._session becomes null
    final entry = manager.endSession();

    // Persist history
    await context
        .read<HistoryViewModel>()
        .saveWithPrEvents(entry, prEvents: prEvents);

    if (!context.mounted) return;

    // Prompt to update template if exercises were modified
    if (exercisesModified && templateId != null) {
      final saveToTemplate = await _askSaveToTemplate(context);
      if (saveToTemplate == true && context.mounted) {
        final vm = context.read<TemplatesViewModel>();
        final template = vm.byId(templateId);
        if (template != null) {
          await vm.updateExercises(template, currentExerciseIds);
        }
      }
    }

    manager.clearAfterEnd();

    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout saved to history')),
    );
  }

  void _showAddExerciseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExerciseSheet(manager: manager),
    );
  }

  // ── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch session VM for timer ticks — already provided by StartSessionPage
    final session = context.watch<WorkoutSessionViewModel>();
    final cs = Theme.of(context).colorScheme;
    final templateName = manager.templateName ?? 'Session';
    final templateId = manager.templateId ?? '';
    final exercises = manager.exercises;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showMinimizeSheet(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(templateName, maxLines: 1, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            tooltip: 'Minimize',
            onPressed: () => _showMinimizeSheet(context),
          ),
          actions: [
            // Timer chip
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 15,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hhmmss(session.elapsed),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Add exercise button
            IconButton(
              tooltip: 'Add / remove exercises',
              icon: const Icon(Icons.playlist_add_rounded),
              onPressed: () => _showAddExerciseSheet(context),
            ),
          ],
        ),
        body: exercises.isEmpty
            ? _EmptyExercisesState(
                templateName: templateName,
                onAddExercise: () => _showAddExerciseSheet(context),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
                itemCount: exercises.length,
                itemBuilder: (context, i) {
                  final ex = exercises[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ExerciseSessionTile(
                      exercise: ex,
                      templateId: templateId,
                    ),
                  );
                },
              ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
            child: Row(
              children: [
                // Volume chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${session.totalWorkSets}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        'sets',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: session.isRunning
                            ? cs.error
                            : cs.primary,
                      ),
                      onPressed: () async {
                        if (!session.isRunning) {
                          session.start();
                          return;
                        }
                        await _endAndSaveSession(context);
                      },
                      child: Text(
                        session.isRunning ? 'End & Save' : 'Start Session',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.color,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurface;

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            )
          : null,
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyExercisesState extends StatelessWidget {
  const _EmptyExercisesState({
    required this.templateName,
    required this.onAddExercise,
  });

  final String templateName;
  final VoidCallback onAddExercise;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_add, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              'No exercises',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add exercises to "$templateName" to start tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(Icons.add),
              label: const Text('Add exercises'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Bottom sheet for adding/removing exercises mid-session.
class _AddExerciseSheet extends StatefulWidget {
  const _AddExerciseSheet({required this.manager});
  final ActiveSessionManager manager;

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allExercises = ExercisesViewModel.all;
    final currentIds = widget.manager.exercises.map((e) => e.id).toSet();

    final filtered = _search.isEmpty
        ? allExercises
        : allExercises
            .where(
              (e) =>
                  e.name.toLowerCase().contains(_search.toLowerCase()),
            )
            .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 60, 0, 0),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exercises',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Search exercises…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final ex = filtered[i];
                final inSession = currentIds.contains(ex.id);

                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Image.asset(
                    ex.workoutImage,
                    width: 36,
                    height: 36,
                    errorBuilder: (context, err, st) => const Icon(Icons.sports_gymnastics),
                  ),
                  title: Text(
                    ex.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    ex.category.displayName,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                  trailing: inSession
                      ? OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.error,
                            side: BorderSide(color: cs.error),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(64, 32),
                          ),
                          onPressed: () {
                            setState(() {});
                            widget.manager.removeExerciseFromSession(ex);
                          },
                          child: const Text('Remove'),
                        )
                      : FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(64, 32),
                          ),
                          onPressed: () {
                            setState(() {});
                            widget.manager.addExerciseToSession(ex);
                          },
                          child: const Text('Add'),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
