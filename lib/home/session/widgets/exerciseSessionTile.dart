import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/history/ViewModel/historyViewModel.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/services/sessionPlannedAutoloadService.dart';
import 'package:workout_tracker/home/session/sessionViewModel.dart';
import 'package:workout_tracker/home/session/widgets/plannedSetControllers.dart';
import 'package:workout_tracker/home/session/widgets/plannedSetRow.dart';

class ExerciseSessionTile extends StatefulWidget {
  final ExerciseModel exercise;
  final String templateId;

  const ExerciseSessionTile({
    super.key,
    required this.exercise,
    required this.templateId,
  });

  @override
  State<ExerciseSessionTile> createState() => _ExerciseSessionTileState();
}

class _ExerciseSessionTileState extends State<ExerciseSessionTile> {
  bool _autoLoaded = false;

  final _controllers = PlannedSetControllers();
  final _autoLoadService = SessionPlanAutoloadService();
  final Set<String> _editingKeys = {};

  List<PerformedSet> _fixWarmupOrder(List<PerformedSet> sets) {
    if (sets.isEmpty) return sets;
    final warmups = sets.where((s) => s.type == SetType.warmup).toList()
      ..sort((a, b) {
        final w = a.weight.compareTo(b.weight);
        return w != 0 ? w : a.reps.compareTo(b.reps);
      });
    final others = sets.where((s) => s.type != SetType.warmup).toList();
    return [...warmups, ...others];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoLoaded) return;
    _autoLoaded = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final session = context.read<WorkoutSessionViewModel>();
      final log = session.logs[widget.exercise.id];
      if (log == null || log.plannedSets.isNotEmpty) return;

      final historyVM = context.read<HistoryViewModel>();
      final lastSets = _autoLoadService.lastWorkoutSetsForExercise(
        historyVM: historyVM,
        templateId: widget.templateId,
        exerciseId: widget.exercise.id,
      );

      final fixed = _fixWarmupOrder(lastSets);
      if (fixed.isEmpty) {
        session.addPlannedSetRow(exerciseId: widget.exercise.id);
      } else {
        session.loadPlannedSetsFromLastWorkout(
          exerciseId: widget.exercise.id,
          lastSets: fixed,
        );
      }
    });
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<WorkoutSessionViewModel>();
    final log = session.logs[widget.exercise.id];

    final planned = log?.plannedSets ?? <PlannedSet>[];
    final doneCount = planned.where((p) => p.done).length;
    final allDone = planned.isNotEmpty && doneCount == planned.length;

    _controllers.cleanupForExercise(
      exerciseId: widget.exercise.id,
      planned: planned,
      editingKeys: _editingKeys,
    );

    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          leading: _ExerciseThumb(ex: widget.exercise, allDone: allDone),
          title: Text(
            widget.exercise.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          subtitle: _ProgressDots(planned: planned, doneCount: doneCount, cs: cs),
          children: [
            // ── Column headers ──────────────────────────────────
            if (planned.isNotEmpty) _ColumnHeader(cs: cs),

            // ── Set rows ────────────────────────────────────────
            if (planned.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'No sets yet',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: planned.length,
                separatorBuilder: (_, i) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final p = planned[i];
                  final rowKey = _controllers.rowKey(widget.exercise.id, p);

                  _controllers.initOnce(rowKey: rowKey, p: p);

                  final wCtrl = _controllers.weightCtrl(rowKey);
                  final rCtrl = _controllers.repsCtrl(rowKey);
                  final isEditing = _editingKeys.contains(rowKey);
                  final prHit = session.prHitForPlannedRow(
                    exerciseId: widget.exercise.id,
                    index: i,
                  );

                  void showInvalidSnack() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a valid weight and rep count'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  bool commitToModel() {
                    final w = double.tryParse(
                      wCtrl.text.trim().replaceAll(',', '.'),
                    );
                    final r = int.tryParse(rCtrl.text.trim());

                    if (w == null || r == null) {
                      showInvalidSnack();
                      return false;
                    }

                    context.read<WorkoutSessionViewModel>().updatePlannedSet(
                      exerciseId: widget.exercise.id,
                      index: i,
                      weight: w,
                      reps: r,
                    );
                    return true;
                  }

                  return PlannedSetRow(
                    exercise: widget.exercise,
                    planned: planned,
                    index: i,
                    rowKey: rowKey,
                    weightController: wCtrl,
                    repsController: rCtrl,
                    isEditing: isEditing,
                    setEditing: (editing) => setState(() {
                      if (editing) {
                        _editingKeys.add(rowKey);
                      } else {
                        _editingKeys.remove(rowKey);
                      }
                    }),
                    prVisible: prHit != null,
                    onToggleType: () {
                      final next = p.type == SetType.work
                          ? SetType.warmup
                          : p.type == SetType.warmup
                          ? SetType.dropset
                          : SetType.work;

                      context.read<WorkoutSessionViewModel>().updatePlannedSet(
                        exerciseId: widget.exercise.id,
                        index: i,
                        type: next,
                      );
                    },
                    onRemove: p.done
                        ? null
                        : () => context
                              .read<WorkoutSessionViewModel>()
                              .removePlannedSetRow(
                                exerciseId: widget.exercise.id,
                                index: i,
                              ),
                    onCancelEdit: () {
                      _controllers.resetToModel(rowKey: rowKey, p: p);
                      setState(() => _editingKeys.remove(rowKey));
                      FocusScope.of(context).unfocus();
                    },
                    onAddOrSave: () {
                      if (!p.done) {
                        final ok = commitToModel();
                        if (!ok) return;

                        context
                            .read<WorkoutSessionViewModel>()
                            .markPlannedSetDone(
                              exerciseId: widget.exercise.id,
                              index: i,
                              history: context
                                  .read<HistoryViewModel>()
                                  .history,
                            );
                        return;
                      }

                      final ok = commitToModel();
                      if (!ok) return;

                      setState(() => _editingKeys.remove(rowKey));
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),

            const SizedBox(height: 10),

            // ── Add set ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add set'),
                onPressed: () => context
                    .read<WorkoutSessionViewModel>()
                    .addPlannedSetRow(
                      exerciseId: widget.exercise.id,
                      type: SetType.work,
                    ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(
                    color: cs.outlineVariant,
                  ),
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

/// Column header row aligned with PlannedSetRow fields.
class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Row(
        children: [
          // badge (38) + gap (10)
          const SizedBox(width: 48),
          Expanded(
            flex: 5,
            child: Text(
              'WEIGHT',
              textAlign: TextAlign.center,
              style: labelStyle.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          // × separator space (6 + ~10 + 6)
          const SizedBox(width: 22),
          Expanded(
            flex: 4,
            child: Text(
              'REPS',
              textAlign: TextAlign.center,
              style: labelStyle.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          // right side: 8 + TapIcon(28) + 8 + LogButton(42) = 86
          const SizedBox(width: 86),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Progress indicator: filled/empty dots + "X/N" count.
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.planned,
    required this.doneCount,
    required this.cs,
  });

  final List<PlannedSet> planned;
  final int doneCount;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (planned.isEmpty) {
      return Text(
        'No sets',
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
      );
    }

    const maxDots = 8;
    final show = planned.length.clamp(0, maxDots);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(show, (i) {
          final done = planned[i].done;
          return Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? context.tokens.success
                  : cs.outlineVariant,
            ),
          );
        }),
        if (planned.length > maxDots)
          Text(
            '+${planned.length - maxDots}',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        const SizedBox(width: 6),
        Text(
          '$doneCount / ${planned.length}',
          style: TextStyle(
            color: doneCount == planned.length
                ? context.tokens.success
                : cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: doneCount == planned.length
                ? FontWeight.w700
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseThumb extends StatelessWidget {
  final ExerciseModel ex;
  final bool allDone;

  const _ExerciseThumb({required this.ex, required this.allDone});

  @override
  Widget build(BuildContext context) {
    final path = ex.workoutImage.isNotEmpty ? ex.workoutImage : null;

    Widget img;
    if (path == null) {
      img = const Icon(Icons.image_not_supported, size: 22);
    } else if (path.startsWith('http')) {
      img = Image.network(path, fit: BoxFit.cover);
    } else {
      img = Image.asset(path, fit: BoxFit.cover);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: img,
          ),
        ),
        if (allDone)
          Positioned(
            bottom: -3,
            right: -3,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.tokens.success,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 11,
              ),
            ),
          ),
      ],
    );
  }
}
