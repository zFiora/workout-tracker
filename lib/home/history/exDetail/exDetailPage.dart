import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/theme/workout_icons.dart';
import 'package:workout_tracker/common/tutorial/tutorial_runner.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:workout_tracker/home/exercises/custom_exercises_repository.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/widgets/customExerciseEditorPage.dart';
import 'package:workout_tracker/home/exercises/widgets/exercise_image.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/headerStatsCard.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/lastSessionCard.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/metricToggle.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/miniSeriesCard.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/notesCard.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/sectionTitle.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/summaryCards.dart';
import 'package:workout_tracker/home/history/exDetail/exDetailViewModel.dart';
import 'package:workout_tracker/home/history/models/exNote.dart';
import 'package:workout_tracker/home/history/repos/exHistoryRepo.dart';
import 'package:workout_tracker/home/session/active_session_manager.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/social/pages/exercise_leaderboard_page.dart';

class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  final int exerciseId;
  final String exerciseName;

  @override
  Widget build(BuildContext context) {
    final historyBox = Hive.box<WorkoutHistoryEntry>('historyBox');
    final notesBox = Hive.box<ExerciseNote>('exerciseNotesBox');

    return ChangeNotifierProvider(
      create: (_) => ExerciseDetailViewModel(
        exerciseId: exerciseId,
        historyRepo: ExerciseHistoryRepository(historyBox),
        notesBox: notesBox,
      ),
      child: _ExerciseDetailView(exerciseName: exerciseName),
    );
  }
}

class _ExerciseDetailView extends StatefulWidget {
  const _ExerciseDetailView({required this.exerciseName});
  final String exerciseName;

  @override
  State<_ExerciseDetailView> createState() => _ExerciseDetailViewState();
}

class _ExerciseDetailViewState extends State<_ExerciseDetailView> {
  final _leaderboardKey = GlobalKey();
  final _prKey = GlobalKey();
  final _notesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    TutorialRunner.schedule(
      context,
      id: Tutorials.exerciseDetails,
      steps: () => [
        CoachMarkStep(
          targetKey: _leaderboardKey,
          title: 'Compare with friends',
          description:
              'Open the leaderboard to see how your best lift on this exercise '
              'ranks against your friends.',
        ),
        CoachMarkStep(
          targetKey: _notesKey,
          title: 'Notes & tips',
          description:
              'Jot down cues, setups or reminders for this exercise — they '
              'stay attached here for next time.',
        ),
        // Conditional: only exists once you have history for this exercise, so
        // it's last to keep the "x of N" numbering contiguous when absent.
        CoachMarkStep(
          targetKey: _prKey,
          title: 'Your PRs & progress',
          description:
              'Once you\'ve logged this exercise, your personal records, '
              'estimated 1RM and progress charts appear here.',
        ),
      ],
    );
  }

  Future<void> _edit(ExerciseModel model) async {
    final updated = await Navigator.of(context).push<ExerciseModel>(
      MaterialPageRoute(
        builder: (_) => CustomExerciseEditorPage(existing: model),
      ),
    );
    if (updated != null && mounted) setState(() {}); // re-lookup fresh model
  }

  Future<void> _delete(ExerciseModel model) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete exercise?'),
        content: Text(
          '"${model.name}" will be removed from your catalog. Your past '
          'workout history is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Intentionally do NOT delete the photo file: completed workouts snapshot
    // this path and must still render the image after the exercise is removed
    // from the catalog. (Orphaned files are negligible; history integrity wins.)
    await CustomExercisesRepository.I.delete(model.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExerciseDetailViewModel>();
    final cs = Theme.of(context).colorScheme;
    final model = ExercisesViewModel.byId(vm.exerciseId);
    final hasHistory = vm.bestSet != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _ExerciseHero(
            exerciseName: widget.exerciseName,
            model: model,
            leaderboardKey: _leaderboardKey,
            onEdit: model != null && model.isCustom ? () => _edit(model) : null,
            onDelete:
                model != null && model.isCustom ? () => _delete(model) : null,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (model != null) _OverviewSection(model: model),
                if (!hasHistory)
                  _NoHistoryNote(cs: cs)
                else ...[
                  const SectionTitle(
                    icon: Icons.emoji_events,
                    title: 'Personal Records',
                  ),
                  const SizedBox(height: 8),
                  KeyedSubtree(key: _prKey, child: HeaderStatsCard(vm: vm)),
                  const SizedBox(height: 10),
                  SummaryCards(vm: vm),
                  const SizedBox(height: 20),
                  const SectionTitle(icon: Icons.show_chart, title: 'Progress'),
                  const SizedBox(height: 8),
                  MetricToggle(vm: vm),
                  const SizedBox(height: 8),
                  MiniSeriesCard(series: vm.series),
                  const SizedBox(height: 20),
                  const SectionTitle(
                    icon: Icons.history,
                    title: 'Recent Sessions',
                  ),
                  const SizedBox(height: 8),
                  LastSessionsCard(vm: vm),
                  const SizedBox(height: 20),
                ],
                const SectionTitle(icon: Icons.note_alt, title: 'Notes & Tips'),
                const SizedBox(height: 8),
                KeyedSubtree(key: _notesKey, child: NotesCard(vm: vm)),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          model == null ? null : _AddToWorkoutBar(exercise: model),
    );
  }
}

/// Overview: primary/secondary muscles, equipment, difficulty, and any
/// instructions / tips / common mistakes that exist. Only shows what's there.
class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.model});
  final ExerciseModel model;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget metaRow(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant)),
              ),
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

    Widget bulletBlock(String title, List<String> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            SectionTitle(icon: Icons.check_circle_outline, title: title),
            const SizedBox(height: 8),
            ...items.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(t, style: const TextStyle(height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(icon: Icons.info_outline_rounded, title: 'Overview'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.tokens.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              metaRow('Primary', model.primaryMuscle),
              if (model.secondaryMuscles.isNotEmpty)
                metaRow('Secondary', model.secondaryMuscles.join(', ')),
              metaRow('Equipment', model.resolvedEquipment),
              if (model.difficulty != null)
                metaRow('Difficulty', model.difficulty!),
            ],
          ),
        ),
        if (model.instructions != null && model.instructions!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionTitle(
              icon: Icons.menu_book_outlined, title: 'How to perform'),
          const SizedBox(height: 8),
          Text(model.instructions!, style: const TextStyle(height: 1.45)),
        ],
        if (model.tips.isNotEmpty) bulletBlock('Tips', model.tips),
        if (model.commonMistakes.isNotEmpty)
          bulletBlock('Common mistakes', model.commonMistakes),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Premium collapsing hero: the exercise's own image behind a scrim, its name,
/// and a muscle-group chip. Uses only real catalog data (image + category).
class _ExerciseHero extends StatelessWidget {
  const _ExerciseHero({
    required this.exerciseName,
    required this.model,
    this.leaderboardKey,
    this.onEdit,
    this.onDelete,
  });

  final String exerciseName;
  final ExerciseModel? model;
  final GlobalKey? leaderboardKey;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 260,
      // Always-dark bar so the white title/back button read once collapsed,
      // in both light and dark themes (the expanded state sits over the
      // image scrim).
      backgroundColor: const Color(0xFF0D1B4B),
      foregroundColor: Colors.white,
      actions: [
        if (model != null)
          KeyedSubtree(
            key: leaderboardKey,
            child: IconButton(
              tooltip: 'Leaderboard',
              icon: const Icon(Icons.leaderboard_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExerciseLeaderboardPage(exercise: model!),
                ),
              ),
            ),
          ),
        if (onEdit != null || onDelete != null)
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) {
              if (v == 'edit') onEdit?.call();
              if (v == 'delete') onDelete?.call();
            },
            itemBuilder: (_) => [
              if (onEdit != null)
                const PopupMenuItem(value: 'edit', child: Text('Edit exercise')),
              if (onDelete != null)
                const PopupMenuItem(
                    value: 'delete', child: Text('Delete exercise')),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 14, right: 56),
        title: Text(
          exerciseName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (model != null && model!.workoutImage.isNotEmpty)
              ExerciseImage(
                path: model!.workoutImage,
                fit: BoxFit.cover,
                fallback: _heroFallback(cs),
              )
            else
              _heroFallback(cs),
            // Scrim so the collapsing title and chip stay legible on any image.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black26, Colors.transparent, Colors.black87],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            if (model != null)
              Positioned(
                left: 16,
                bottom: 54,
                child: _MuscleChip(category: model!.category),
              ),
          ],
        ),
      ),
    );
  }

  Widget _heroFallback(ColorScheme cs) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary.withValues(alpha: 0.4), cs.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(Icons.fitness_center_rounded,
              size: 64, color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.category});
  final WorkoutCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkoutIconImage(category.iconKey, width: 16, height: 16),
          const SizedBox(width: 6),
          Text(
            category.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoHistoryNote extends StatelessWidget {
  const _NoHistoryNote({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.tokens.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No history yet. Log this exercise in a workout and your PRs, '
              'progress and recent sessions will show up here.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary action, one-hand reachable: add this exercise to the workout in
/// progress. Only shown while a session is active (real functionality via
/// [ActiveSessionManager]) — never fabricates a start-flow that doesn't exist.
class _AddToWorkoutBar extends StatelessWidget {
  const _AddToWorkoutBar({required this.exercise});
  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ActiveSessionManager>();
    if (!manager.hasActiveSession) return const SizedBox.shrink();

    final alreadyIn = manager.exercises.any((e) => e.id == exercise.id);
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: alreadyIn
              ? null
              : () {
                  manager.addExerciseToSession(exercise);
                  Mycustomsnackbar.show(
                    context,
                    message: 'Added to your workout',
                    type: SnackbarType.success,
                  );
                },
          icon: Icon(alreadyIn ? Icons.check_rounded : Icons.add_rounded),
          label: Text(alreadyIn ? 'Already in workout' : 'Add to workout'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: alreadyIn ? cs.surfaceContainerHigh : null,
            foregroundColor: alreadyIn ? cs.onSurfaceVariant : null,
          ),
        ),
      ),
    );
  }
}
