import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_tracker/common/formatters/duarationFormatter.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/tutorial/tutorial_runner.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/core/auth_token.dart';
import 'package:workout_tracker/home/account/accountViewModel.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/history/ViewModel/historyViewModel.dart';
import 'package:workout_tracker/home/session/active_session_manager.dart';
import 'package:workout_tracker/home/session/sessionViewModel.dart';
import 'package:workout_tracker/home/session/widgets/exerciseSessionTile.dart';
import 'package:workout_tracker/home/session/widgets/reorder_exercises_sheet.dart';
import 'package:workout_tracker/home/session/widgets/rest_timer_bar.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';

/// What to do with the source template when a session's exercise list ended
/// up different from it. See `_askTemplateAction`.
enum _TemplateEndAction { saveAsNew, updateCurrent, doNothing }

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

class _SessionBody extends StatefulWidget {
  const _SessionBody({required this.manager});
  final ActiveSessionManager manager;

  @override
  State<_SessionBody> createState() => _SessionBodyState();
}

class _SessionBodyState extends State<_SessionBody> {
  // Existing method bodies below refer to `manager` — keep them working by
  // exposing it as a getter rather than rewriting every call site.
  ActiveSessionManager get manager => widget.manager;

  // Coach-mark spotlight targets (see the workout tutorial).
  final _firstTileKey = GlobalKey();
  final _addExerciseKey = GlobalKey();
  final _reorderKey = GlobalKey();
  final _minimizeKey = GlobalKey();
  final _endSaveKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    TutorialRunner.schedule(
      context,
      id: Tutorials.workout,
      steps: _tutorialSteps,
    );
  }

  List<CoachMarkStep> _tutorialSteps() {
    final multipleExercises = manager.exercises.length > 1;
    return [
      CoachMarkStep(
        targetKey: _firstTileKey,
        title: 'Log your sets',
        description:
            'Enter your weight and reps for each set, then tap the ✓ to log '
            'it. A rest timer starts automatically after each working set — '
            'you can adjust or skip it from the bar that appears.',
      ),
      if (multipleExercises)
        CoachMarkStep(
          targetKey: _reorderKey,
          title: 'Reorder exercises',
          description:
              'Rearrange the order you train your exercises in without losing '
              'any sets you\'ve already logged.',
        ),
      CoachMarkStep(
        targetKey: _addExerciseKey,
        title: 'Add or remove exercises',
        description:
            'Change your lineup mid-workout — add something new or drop an '
            'exercise you\'re skipping today.',
      ),
      CoachMarkStep(
        targetKey: _minimizeKey,
        title: 'Keep it running',
        description:
            'Minimize the session to browse the rest of the app while your '
            'workout and timer keep running in the background.',
      ),
      CoachMarkStep(
        targetKey: _endSaveKey,
        title: 'Finish & save',
        description:
            'When you\'re done, save the workout to your history. Personal '
            'records are detected and celebrated automatically.',
      ),
    ];
  }

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

  /// The exercise list ended up different from the template this session
  /// started from (added/removed/reordered). Exactly three outcomes — see
  /// `_endAndSaveSession` for what each does.
  Future<_TemplateEndAction?> _askTemplateAction(
    BuildContext context,
    String templateName,
  ) {
    return showDialog<_TemplateEndAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exercises changed'),
        content: Text(
          'Your exercises for this workout ended up different from '
          '"$templateName". What should happen to the template?',
        ),
        actionsAlignment: MainAxisAlignment.start,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          _TemplateActionButton(
            icon: Icons.bookmark_add_outlined,
            label: 'Save as a new template',
            subtitle: '"$templateName" stays exactly as it was',
            onTap: () =>
                Navigator.pop(ctx, _TemplateEndAction.saveAsNew),
          ),
          _TemplateActionButton(
            icon: Icons.edit_note_rounded,
            label: 'Update & save current template',
            subtitle: 'Applies these changes to "$templateName" itself',
            onTap: () =>
                Navigator.pop(ctx, _TemplateEndAction.updateCurrent),
          ),
          _TemplateActionButton(
            icon: Icons.check_circle_outline_rounded,
            label: 'Do nothing',
            subtitle: 'Just this workout — the template is unaffected',
            onTap: () => Navigator.pop(ctx, _TemplateEndAction.doNothing),
          ),
        ],
      ),
    );
  }

  /// Follow-up for "Save as a new template" — lets the user confirm/edit the
  /// suggested name. Returns null if cancelled.
  Future<String?> _askNewTemplateName(
    BuildContext context,
    String suggestedName,
  ) {
    final controller = TextEditingController(text: suggestedName);
    return showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name the new template'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Template name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(ctx, text.isEmpty ? suggestedName : text);
            },
            child: const Text('Create'),
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
                  style: Theme.of(context).textTheme.headlineSmall,
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

    // The instant endSession() nulls the active session, StartSessionPage
    // rebuilds to a spinner and THIS widget (_SessionBody) is unmounted — so
    // its `context` dies. Capture everything that must outlive it *now*:
    // the root navigator/messenger and the view-models. Using `context`
    // after endSession() (the old code did) hit `!context.mounted` and
    // silently returned, leaving the spinner up forever even though the save
    // had already succeeded.
    final navigator = Navigator.of(context);
    final dialogContext = navigator.context; // alive after _SessionBody unmounts
    final messenger = ScaffoldMessenger.of(context);
    final historyVM = context.read<HistoryViewModel>();
    final accountVM = context.read<AccountViewModel>();
    final templatesVM = context.read<TemplatesViewModel>();

    final prEvents =
        session.prHits.values.map((h) => h.toJson()).toList(growable: false);
    final exercisesModified = manager.exercisesWereModified;
    final templateId = manager.templateId;
    final templateName = manager.templateName ?? 'Template';
    final templateIcon = manager.templateIcon;
    final currentExerciseIds = manager.exercises.map((e) => e.id).toList();

    // End session — timer stops, manager._session becomes null.
    final entry = manager.endSession();

    var saveFailed = false;
    try {
      // Persist to history (local Hive save is the source of truth; the
      // backend push inside is best-effort and never throws here).
      await historyVM.saveWithPrEvents(entry, prEvents: prEvents);

      // Streak is server-owned; refresh so the badge reflects it. Not awaited.
      if (AuthToken.I.isValid) accountVM.refresh();

      // Ask what to do with the template if the exercise list ended up
      // different (added / removed / reordered). Uses the navigator's own
      // (still-mounted) context, not this widget's dead one.
      if (exercisesModified && templateId != null) {
        final action = await _askTemplateAction(dialogContext, templateName);
        switch (action) {
          case _TemplateEndAction.updateCurrent:
            final template = templatesVM.byId(templateId);
            if (template != null) {
              await templatesVM.updateExercises(template, currentExerciseIds);
            }
          case _TemplateEndAction.saveAsNew:
            final newName = await _askNewTemplateName(
              dialogContext,
              '$templateName - Modified',
            );
            if (newName != null) {
              final now = DateTime.now();
              await templatesVM.addTemplate(
                WorkoutTemplateModel(
                  id: const Uuid().v4(),
                  name: newName,
                  iconPath: templateIcon ?? '',
                  exerciseIds: currentExerciseIds,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
            }
          case _TemplateEndAction.doNothing:
          case null: // dismissed — treat as "do nothing"
            break;
        }
      }
    } catch (_) {
      saveFailed = true;
    } finally {
      // ALWAYS leave the (now session-less) page — there is no path that can
      // strand the user on the spinner.
      manager.clearAfterEnd();
      navigator.popUntil((route) => route.isFirst);
      messenger.clearSnackBars();
      Mycustomsnackbar.show(
        dialogContext,
        message: saveFailed
            ? "Couldn't fully save your workout. Please check History."
            : 'Workout saved to history',
        type: saveFailed ? SnackbarType.warning : SnackbarType.success,
      );
    }
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
          leading: KeyedSubtree(
            key: _minimizeKey,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              tooltip: 'Minimize',
              onPressed: () => _showMinimizeSheet(context),
            ),
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
                    color: session.isRunning
                        ? cs.primary.withValues(alpha: 0.14)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: session.isRunning
                          ? cs.primary.withValues(alpha: 0.4)
                          : cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 15,
                        color: session.isRunning
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hhmmss(session.elapsed),
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.6,
                          color: session.isRunning
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Reorder exercises (compact sheet — never drags the live cards)
            if (exercises.length > 1)
              KeyedSubtree(
                key: _reorderKey,
                child: IconButton(
                  tooltip: 'Reorder exercises',
                  icon: const Icon(Icons.swap_vert_rounded),
                  onPressed: () => ReorderExercisesSheet.show(
                    context,
                    exercises: exercises,
                    onReorder: manager.reorderExercise,
                  ),
                ),
              ),
            // Add / remove exercises
            KeyedSubtree(
              key: _addExerciseKey,
              child: IconButton(
                tooltip: 'Add / remove exercises',
                icon: const Icon(Icons.playlist_add_rounded),
                onPressed: () => _showAddExerciseSheet(context),
              ),
            ),
          ],
        ),
        body: exercises.isEmpty
            ? _EmptyExercisesState(
                templateName: templateName,
                onAddExercise: () => _showAddExerciseSheet(context),
              )
            // A plain list — reordering happens in a dedicated compact sheet
            // (the app-bar "Reorder" action). Dragging the live, expanded set
            // cards directly is what produced the broken giant-gray-box drag.
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
                itemCount: exercises.length,
                itemBuilder: (context, i) {
                  final ex = exercises[i];
                  final tile = ExerciseSessionTile(
                    exercise: ex,
                    templateId: templateId,
                  );
                  return Padding(
                    key: ValueKey(ex.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    // Spotlight the first tile for the "log your sets" step.
                    child: i == 0
                        ? KeyedSubtree(key: _firstTileKey, child: tile)
                        : tile,
                  );
                },
              ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RestTimerBar(),
            SafeArea(
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
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${session.totalWorkSets}',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        'SETS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KeyedSubtree(
                    key: _endSaveKey,
                    child: VoltButton(
                      height: 52,
                      danger: session.isRunning,
                      icon: session.isRunning
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      label: session.isRunning ? 'End & Save' : 'Start Session',
                      onPressed: () async {
                        if (!session.isRunning) {
                          session.start();
                          return;
                        }
                        await _endAndSaveSession(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// One row of the end-of-session template-action dialog. A plain ListTile
/// (rather than AlertDialog's usual TextButton row) since these three
/// options need room for a label + explanatory subtitle each.
class _TemplateActionButton extends StatelessWidget {
  const _TemplateActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    return EmptyState(
      icon: Icons.playlist_add_rounded,
      title: 'No exercises',
      message: 'Add exercises to "$templateName"\nto start tracking.',
      actionLabel: 'Add exercises',
      onAction: onAddExercise,
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
        color: Theme.of(context).bottomSheetTheme.backgroundColor ?? cs.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        children: [
          const SheetHeader(title: 'Exercises'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'Search exercises…',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
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
