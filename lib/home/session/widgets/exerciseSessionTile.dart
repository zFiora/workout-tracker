import 'package:flutter/material.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoLoaded) return;
    _autoLoaded = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final session = context.read<WorkoutSessionViewModel>();
      final log = session.logs[widget.exercise.id];
      if (log == null) return;

      if (log.plannedSets.isNotEmpty) return;

      final historyVM = context.read<HistoryViewModel>();
      final lastSets = _autoLoadService.lastWorkoutSetsForExercise(
        historyVM: historyVM,
        templateId: widget.templateId,
        exerciseId: widget.exercise.id,
      );

      if (lastSets.isEmpty) {
        session.addPlannedSetRow(exerciseId: widget.exercise.id);
      } else {
        session.loadPlannedSetsFromLastWorkout(
          exerciseId: widget.exercise.id,
          lastSets: lastSets,
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

    _controllers.cleanupForExercise(
      exerciseId: widget.exercise.id,
      planned: planned,
      editingKeys: _editingKeys,
    );

    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: _ExerciseThumb(ex: widget.exercise),
          title: Text(
            widget.exercise.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: planned.isEmpty
              ? const Text('No sets')
              : Text('$doneCount / ${planned.length} done'),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            if (planned.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'No plan yet',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: planned.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                        content: Text('Enter valid weight and reps'),
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
                    setEditing: (editing) {
                      setState(() {
                        if (editing) {
                          _editingKeys.add(rowKey);
                        } else {
                          _editingKeys.remove(rowKey);
                        }
                      });
                    },
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

                        final history = context
                            .read<HistoryViewModel>()
                            .history;

                        context
                            .read<WorkoutSessionViewModel>()
                            .markPlannedSetDone(
                              exerciseId: widget.exercise.id,
                              index: i,
                              history: history,
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

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add set'),
                onPressed: () =>
                    context.read<WorkoutSessionViewModel>().addPlannedSetRow(
                      exerciseId: widget.exercise.id,
                      type: SetType.work,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseThumb extends StatelessWidget {
  final ExerciseModel ex;
  const _ExerciseThumb({required this.ex});

  @override
  Widget build(BuildContext context) {
    final path = ex.workoutImage.isNotEmpty ? ex.workoutImage : null;

    Widget child;
    if (path == null) {
      child = const Icon(Icons.image_not_supported, size: 20);
    } else if (path.startsWith('http')) {
      child = Image.network(path, fit: BoxFit.cover);
    } else {
      child = Image.asset(path, fit: BoxFit.cover);
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: ClipRRect(borderRadius: BorderRadius.circular(10), child: child),
    );
  }
}
