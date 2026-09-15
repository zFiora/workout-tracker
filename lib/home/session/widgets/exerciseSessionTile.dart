import 'package:flutter/material.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/units/weight_unit.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/widgets/exercise_image.dart';
import 'package:workout_tracker/home/history/ViewModel/historyViewModel.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/rest_timer_manager.dart';
import 'package:workout_tracker/home/session/services/progressive_overload_service.dart';
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
  static const _progression = ProgressiveOverloadService();
  final Set<String> _editingKeys = {};

  // Progressive-overload suggestion, computed once from last time's sets.
  List<ProgressionTarget> _targets = const [];
  List<PerformedSet> _lastWork = const [];
  bool _progressionDismissed = false;

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

      // Cache a progression suggestion for the banner (offered, never forced).
      final targets = _progression.suggestFrom(fixed);
      if (targets.isNotEmpty && _progression.differsFrom(targets, fixed)) {
        setState(() {
          _targets = targets;
          _lastWork = fixed.where((s) => s.type == SetType.work).toList();
        });
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
    final unit = context.select<AppManager, WeightUnit>((m) => m.weightUnit);
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
            // ── Progressive-overload suggestion (offered, not forced) ──
            if (_targets.isNotEmpty &&
                !_progressionDismissed &&
                planned.any((p) => !p.done))
              _ProgressionBanner(
                targets: _targets,
                lastWork: _lastWork,
                unit: unit,
                onApply: () {
                  context.read<WorkoutSessionViewModel>().applyProgressionTargets(
                        exerciseId: widget.exercise.id,
                        targets: _targets
                            .map((t) => (weightKg: t.weightKg, reps: t.reps))
                            .toList(),
                      );
                  setState(() => _progressionDismissed = true);
                },
                onDismiss: () => setState(() => _progressionDismissed = true),
              ),

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

                  _controllers.initOnce(rowKey: rowKey, p: p, unit: unit);

                  final wCtrl = _controllers.weightCtrl(rowKey);
                  final rCtrl = _controllers.repsCtrl(rowKey);
                  final isEditing = _editingKeys.contains(rowKey);
                  final prHit = session.prHitForPlannedRow(
                    exerciseId: widget.exercise.id,
                    index: i,
                  );

                  void showInvalidSnack() {
                    Mycustomsnackbar.show(
                      context,
                      message: 'Enter a valid weight and rep count',
                      type: SnackbarType.warning,
                    );
                  }

                  bool commitToModel() {
                    final wDisplay = double.tryParse(
                      wCtrl.text.trim().replaceAll(',', '.'),
                    );
                    final r = int.tryParse(rCtrl.text.trim());

                    if (wDisplay == null || r == null) {
                      showInvalidSnack();
                      return false;
                    }

                    // Text is in the user's unit; store canonical kg.
                    context.read<WorkoutSessionViewModel>().updatePlannedSet(
                      exerciseId: widget.exercise.id,
                      index: i,
                      weight: unit.toKg(wDisplay),
                      reps: r,
                    );
                    return true;
                  }

                  return PlannedSetRow(
                    exercise: widget.exercise,
                    planned: planned,
                    index: i,
                    rowKey: rowKey,
                    weightUnitLabel: unit.label,
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
                      _controllers.resetToModel(
                          rowKey: rowKey, p: p, unit: unit);
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
                        // Auto-start rest after a completed *work* set.
                        if (p.type == SetType.work) {
                          context.read<RestTimerManager>().start();
                        }
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

/// Compact, dismissible progressive-overload suggestion shown above the set
/// rows. Purely optional — "Apply" fills the planned targets, and the user can
/// still edit anything afterwards.
class _ProgressionBanner extends StatelessWidget {
  const _ProgressionBanner({
    required this.targets,
    required this.lastWork,
    required this.unit,
    required this.onApply,
    required this.onDismiss,
  });

  final List<ProgressionTarget> targets;
  final List<PerformedSet> lastWork;
  final WeightUnit unit;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  String _summary() {
    // Collapse identical consecutive targets: "102.5×8 ×2, 100×10".
    final parts = <String>[];
    for (final t in targets) {
      parts.add('${unit.format(t.weightKg)}×${t.reps}');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progression',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: cs.primary,
                  ),
                ),
                Text(
                  'Try ${_summary()}',
                  style: TextStyle(fontSize: 12.5, color: cs.onSurface),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onApply,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('Apply'),
          ),
          InkResponse(
            onTap: onDismiss,
            radius: 18,
            child: Icon(Icons.close_rounded, size: 16, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            // Handles bundled assets AND custom-exercise file-path photos.
            child: ExerciseImage(
              path: ex.workoutImage,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
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
