import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/formatters/dateTimeFormatter.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/tutorial/tutorial_runner.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/core/services/sync_coordinator.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/history/ViewModel/historyViewModel.dart';
import 'package:workout_tracker/home/history/services/next_workout_suggestion_service.dart';
import 'package:workout_tracker/home/session/active_session_manager.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/pages/startSessionPage.dart';
import 'package:workout_tracker/common/theme/workout_icons.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/navigation/startSessionFlow.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';
import 'package:workout_tracker/home/templates/pages/createTemplatePage.dart';
import 'package:workout_tracker/home/templates/widgets/templateActionMenu.dart';
import 'package:workout_tracker/home/templates/widgets/templateCard.dart';
import 'package:workout_tracker/home/templates/pages/viewTemplatePage.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  final _firstCardKey = GlobalKey();
  final _actionsKey = GlobalKey();
  final _newTemplateKey = GlobalKey();
  final _topCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    TutorialRunner.schedule(
      context,
      id: Tutorials.templates,
      steps: _tutorialSteps,
    );
  }

  List<CoachMarkStep> _tutorialSteps() => [
        CoachMarkStep(
          targetKey: _firstCardKey,
          title: 'Your workout templates',
          description:
              'Tap a template to view its exercises, then Start to begin a '
              'tracked session in one tap.',
        ),
        CoachMarkStep(
          targetKey: _actionsKey,
          title: 'Template actions',
          description:
              'Edit exercises, change the icon, share a template with a '
              'friend, or delete it — all from this menu.',
        ),
        CoachMarkStep(
          targetKey: _newTemplateKey,
          title: 'Build a new template',
          description:
              'Create a reusable workout: pick an icon, name it and add your '
              'exercises. It becomes a one-tap start every time.',
        ),
        // Conditional (needs history / an active session) → last so numbering
        // stays contiguous when it isn't showing.
        CoachMarkStep(
          targetKey: _topCardKey,
          title: 'Suggested next',
          description:
              'Based on your recent workouts, we surface what to train next '
              '(or let you resume an in-progress session) right here.',
        ),
      ];

  Future<String?> _pickIcon(BuildContext ctx, {required String current}) {
    final cs = Theme.of(ctx).colorScheme;
    return showModalBottomSheet<String>(
      context: ctx,
      builder: (c) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeader(title: 'Choose an icon'),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: WorkoutIcons.pickerKeys.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (_, i) {
                  final key = WorkoutIcons.pickerKeys[i];
                  // Compare by logical key so a legacy stored path still
                  // highlights its matching icon.
                  final selected = WorkoutIcons.keyFromStored(current) == key;
                  return Pressable(
                    onTap: () => Navigator.pop(c, key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary.withValues(alpha: 0.15)
                            : cs.surfaceContainerHigh,
                        border: Border.all(
                          color: selected ? cs.primary : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: WorkoutIconImage(key),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareTemplate(
    BuildContext context,
    String templateId,
    Map<String, dynamic> templateJson,
  ) async {
    final isOnline = context.read<AppManager>().isOnline;
    if (!isOnline) {
      Mycustomsnackbar.show(
        context,
        message: 'Sign in to share templates',
      );
      return;
    }

    final ok = await SyncCoordinator().shareTemplate(templateJson);

    if (!context.mounted) return;
    Mycustomsnackbar.show(
      context,
      message: ok ? 'Template shared with friends' : 'Share failed. Try again.',
      type: ok ? SnackbarType.success : SnackbarType.warning,
    );
  }

  /// Resolves a history entry's exercises back to [ExerciseModel]s — prefers
  /// the live template (picks up any edits since), falls back to whatever
  /// exercises were actually logged if the template was since deleted.
  List<ExerciseModel> _resolveRepeatExercises(
    WorkoutHistoryEntry entry,
    WorkoutTemplateModel? template,
  ) {
    final byId = {for (final e in ExercisesViewModel.all) e.id: e};
    final ids = template?.exerciseIds ??
        entry.logs.map((l) => l.exerciseId).toList();
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  void _repeatLastWorkout(BuildContext context, WorkoutHistoryEntry entry) {
    final template = context.read<TemplatesViewModel>().byId(entry.templateId);
    final exercises = _resolveRepeatExercises(entry, template);
    if (exercises.isEmpty) {
      Mycustomsnackbar.show(
        context,
        message: "This workout's exercises aren't available anymore.",
        type: SnackbarType.warning,
      );
      return;
    }
    StartSessionFlow.push(
      context: context,
      templateId: template?.id ?? entry.templateId,
      templateName: template?.name ?? entry.templateName,
      templateIcon: template?.iconPath ?? entry.templateIcon,
      exercises: exercises,
    );
  }

  void _startTemplate(BuildContext context, WorkoutTemplateModel template) {
    final byId = {for (final e in ExercisesViewModel.all) e.id: e};
    final exercises = [
      for (final id in template.exerciseIds)
        if (byId[id] != null) byId[id]!,
    ];
    if (exercises.isEmpty) {
      Mycustomsnackbar.show(
        context,
        message: 'Add exercises to this template before starting it.',
        type: SnackbarType.warning,
      );
      return;
    }
    StartSessionFlow.push(
      context: context,
      templateId: template.id,
      templateName: template.name,
      templateIcon: template.iconPath,
      exercises: exercises,
    );
  }

  /// "You usually train Back after Chest → start a Back day" — the split-aware
  /// upgrade to the plain repeat card. [template] is the live, re-resolved
  /// template for the suggestion (so name/exercises are current).
  Widget _suggestionCard(
    BuildContext context,
    NextWorkoutSuggestion suggestion,
    WorkoutTemplateModel template,
  ) {
    final cs = Theme.of(context).colorScheme;
    // Softer wording for a single observation; confident wording once it's a
    // repeated habit.
    final reason = suggestion.timesObserved >= 2
        ? 'You usually train this after ${suggestion.afterTemplateName}'
        : 'Last time after ${suggestion.afterTemplateName}, you trained this';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AppCard(
        onTap: () => _startTemplate(context, template),
        borderColor: cs.primary.withValues(alpha: 0.4),
        child: Row(
          children: [
            IconBadge(icon: Icons.auto_awesome_rounded, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUGGESTED NEXT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _startTemplate(context, template),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _continueCard(BuildContext context, ActiveSessionManager session) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AppCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StartSessionPage()),
        ),
        borderColor: cs.primary.withValues(alpha: 0.4),
        child: Row(
          children: [
            IconBadge(icon: Icons.fitness_center_rounded, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORKOUT IN PROGRESS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.templateName ?? 'Active session',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _recentWorkoutCard(BuildContext context, WorkoutHistoryEntry entry) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AppCard(
        onTap: () => _repeatLastWorkout(context, entry),
        child: Row(
          children: [
            IconBadge(icon: Icons.replay_rounded, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAST WORKOUT · ${dayLabel(entry.endedAt)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.templateName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => _repeatLastWorkout(context, entry),
              child: const Text('Repeat'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TemplatesViewModel>();
    final templates = vm.templates;
    final exercises = ExercisesViewModel.all;
    final activeSession = context.watch<ActiveSessionManager>();
    final history = context.watch<HistoryViewModel>().history;

    void openCreate() => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateTemplatePage(exercises: exercises),
          ),
        );

    // Home-screen "what should I do right now" surface, in priority order:
    //   1. An active session always wins — finish what you started.
    //   2. A split-aware "suggested next" (what you usually train after your
    //      last workout), when history reveals a repeatable pattern AND that
    //      template still exists.
    //   3. Otherwise a plain "repeat last workout".
    // Only ever one card — avoids clutter.
    Widget? topCard;
    if (activeSession.hasActiveSession) {
      topCard = _continueCard(context, activeSession);
    } else if (history.isNotEmpty) {
      final suggestion =
          const NextWorkoutSuggestionService().suggest(history);
      final suggestedTemplate =
          suggestion == null ? null : vm.byId(suggestion.suggestedTemplateId);

      if (suggestion != null && suggestedTemplate != null) {
        topCard = _suggestionCard(context, suggestion, suggestedTemplate);
      } else {
        final mostRecent =
            history.reduce((a, b) => a.endedAt.isAfter(b.endedAt) ? a : b);
        topCard = _recentWorkoutCard(context, mostRecent);
      }
    }

    return MyCustomeScaffoldView(
      title: 'Workouts',
      body: Column(
        children: [
          if (topCard != null)
            KeyedSubtree(key: _topCardKey, child: topCard),
          Expanded(
            child: templates.isEmpty
                ? EmptyState(
                    icon: Icons.fitness_center_rounded,
                    title: 'No workouts yet',
                    message:
                        'Build your first template and it becomes\na one-tap start for every session.',
                    actionLabel: 'Create template',
                    onAction: openCreate,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      final card = TemplateCard(
                        template: template,
                        onOpen: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ViewTemplatePage(template: template),
                          ),
                        ),
                      );
                      final actions = TemplateActionsMenu(
                        template: template,
                        pickIcon: (ctx) =>
                            _pickIcon(ctx, current: template.iconPath),
                        onShare: () => _shareTemplate(
                          context,
                          template.id,
                          template.toJson(),
                        ),
                      );
                      return FadeRiseIn(
                        index: index,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned.fill(
                              // Spotlight the first card / its menu for the
                              // templates tutorial.
                              child: index == 0
                                  ? KeyedSubtree(key: _firstCardKey, child: card)
                                  : card,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: index == 0
                                  ? KeyedSubtree(
                                      key: _actionsKey, child: actions)
                                  : actions,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (templates.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: VoltButton(
                  key: _newTemplateKey,
                  label: 'New Template',
                  icon: Icons.add_rounded,
                  onPressed: openCreate,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
