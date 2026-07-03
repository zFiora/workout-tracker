import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/navigation/startSessionFlow.dart';

class ViewTemplatePage extends StatelessWidget {
  final WorkoutTemplateModel template;

  const ViewTemplatePage({super.key, required this.template});

  List<ExerciseModel> _resolveExercises() {
    final all = ExercisesViewModel.all;
    final mapById = {for (final e in all) e.id: e};

    return [
      for (final id in template.exerciseIds)
        if (mapById[id] != null) mapById[id]!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final resolved = _resolveExercises();
    final categories =
        resolved.map((e) => e.category.displayName).toSet().length;

    return MyCustomeScaffoldView(
      title: '',
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
              child: Image.asset(
                template.iconPath,
                errorBuilder: (_, _, _) => Icon(
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
              template.name,
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

          if (resolved.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: VoltButton(
                  label: 'Start Session',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    StartSessionFlow.push(
                      context: context,
                      templateId: template.id,
                      templateName: template.name,
                      templateIcon: template.iconPath,
                      exercises: resolved,
                    );
                  },
                ),
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
            child: Image.asset(
              exercise.workoutImage,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 52,
                height: 52,
                color: cs.surfaceContainerHigh,
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: cs.onSurfaceVariant,
                ),
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
                    Image.asset(
                      exercise.category.icon,
                      width: 14,
                      height: 14,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
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
