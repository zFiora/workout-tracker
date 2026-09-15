import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/common/theme/workout_icons.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/widgets/exercise_image.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/navigation/startSessionFlow.dart';
import 'package:workout_tracker/home/templates/pages/editTemplatePage.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';

class ViewTemplatePage extends StatelessWidget {
  final WorkoutTemplateModel template;

  /// When true, this is a friend's shared template being previewed — the page
  /// is read-only (no Edit) and the primary action becomes "Save to My
  /// Templates" (creates an independent copy owned by the current user).
  final bool isFriendTemplate;

  const ViewTemplatePage({
    super.key,
    required this.template,
    this.isFriendTemplate = false,
  });

  List<ExerciseModel> _resolveExercises(WorkoutTemplateModel live) {
    final all = ExercisesViewModel.all;
    final mapById = {for (final e in all) e.id: e};

    return [
      for (final id in live.exerciseIds)
        if (mapById[id] != null) mapById[id]!,
    ];
  }

  /// Saves an independent copy of a friend's shared template into the current
  /// user's own templates. New UUID (owned by this user via the auth token on
  /// push), and only exercises this device actually has are copied — custom
  /// exercises the sender has but the recipient doesn't are dropped (the
  /// current share format carries exercise ids, not custom definitions).
  Future<void> _saveCopy(
    BuildContext context,
    WorkoutTemplateModel source,
    List<ExerciseModel> resolved,
  ) async {
    final vm = context.read<TemplatesViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ids = resolved.map((e) => e.id).toList();

    if (ids.isEmpty) {
      Mycustomsnackbar.show(
        context,
        message: "This template's exercises aren't in your catalog.",
        type: SnackbarType.warning,
      );
      return;
    }

    // Avoid an obvious double-save: same name + same exercise set already local.
    final already = vm.templates.any((t) =>
        t.name == source.name &&
        t.exerciseIds.length == ids.length &&
        t.exerciseIds.toSet().containsAll(ids));
    if (already) {
      Mycustomsnackbar.show(context, message: 'Already in your templates');
      navigator.pop();
      return;
    }

    final now = DateTime.now();
    await vm.addTemplate(
      WorkoutTemplateModel(
        id: const Uuid().v4(),
        name: source.name,
        iconPath: source.iconPath,
        exerciseIds: ids,
        createdAt: now,
        updatedAt: now,
      ),
    );

    messenger.clearSnackBars();
    Mycustomsnackbar.show(
      context,
      message: 'Saved to your templates',
      type: SnackbarType.success,
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Templates are now editable from several places (this page, the list's
    // card menu) — always show the current data rather than the snapshot
    // this page was opened with, so an edit made elsewhere doesn't leave
    // this screen showing stale exercises.
    final vm = context.watch<TemplatesViewModel>();
    final live = vm.byId(template.id) ?? template;

    final resolved = _resolveExercises(live);
    final categories =
        resolved.map((e) => e.category.displayName).toSet().length;

    return MyCustomeScaffoldView(
      title: '',
      customAppBar: AppBar(
        title: const Text(''),
        actions: [
          // A friend's shared template is read-only — you save a copy, not edit
          // theirs.
          if (!isFriendTemplate)
            IconButton(
              tooltip: 'Edit template',
              icon: const Icon(Icons.edit_note_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditTemplatePage(
                    template: live,
                    allExercises: ExercisesViewModel.all,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),

          // ── Hero header ─────────────────────────────────────────────
          Hero(
            tag: 'tpl-icon-${template.id}',
            child: Container(
              width: 108,
              height: 108,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.24),
                    cs.primary.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
              ),
              child: WorkoutIconImage(
                live.iconPath,
                fallback: Icon(
                  Icons.fitness_center_rounded,
                  size: 48,
                  color: cs.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              live.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.headlineMedium,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatPill(
                icon: Icons.list_alt_rounded,
                label: '${resolved.length} exercises',
                color: cs.primary,
                filled: true,
              ),
              const SizedBox(width: 8),
              StatPill(
                icon: Icons.category_rounded,
                label:
                    '$categories ${categories == 1 ? "muscle group" : "muscle groups"}',
                color: context.tokens.warning,
                filled: true,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Exercise list ───────────────────────────────────────────
          Expanded(
            child: resolved.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Exercises not found',
                    message:
                        'The exercises saved in this template are\nno longer in the catalog.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: resolved.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final ex = resolved[index];
                      return FadeRiseIn(
                        index: index,
                        child: _TemplateExerciseRow(
                          index: index + 1,
                          exercise: ex,
                        ),
                      );
                    },
                  ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: isFriendTemplate
                  // Friend's template: primary action is to save a copy.
                  ? VoltButton(
                      label: 'Save to My Templates',
                      icon: Icons.bookmark_add_rounded,
                      onPressed: () => _saveCopy(context, live, resolved),
                    )
                  : (resolved.isNotEmpty
                      ? VoltButton(
                          label: 'Start Session',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () {
                            StartSessionFlow.push(
                              context: context,
                              templateId: live.id,
                              templateName: live.name,
                              templateIcon: live.iconPath,
                              exercises: resolved,
                            );
                          },
                        )
                      : const SizedBox.shrink()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateExerciseRow extends StatelessWidget {
  const _TemplateExerciseRow({required this.index, required this.exercise});

  final int index;
  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(10),
      radius: AppRadius.lg,
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$index',
              textAlign: TextAlign.center,
              style: tt.titleLarge?.copyWith(
                fontFamily: AppFonts.display,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              width: 52,
              height: 52,
              color: cs.surfaceContainerHigh,
              child: ExerciseImage(
                path: exercise.workoutImage,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleSmall,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    WorkoutIconImage(
                      exercise.category.iconKey,
                      width: 14,
                      height: 14,
                      fallback: const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      exercise.category.displayName,
                      style: tt.labelMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
