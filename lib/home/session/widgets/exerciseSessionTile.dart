import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/history/historyViewModel.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/sessionViewModel.dart';

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

  List<PerformedSet> _lastWorkoutSetsForExercise({
    required HistoryViewModel historyVM,
    required String templateId,
    required int exerciseId,
  }) {
    if (historyVM.history.isEmpty) return const [];

    final templateEntries = historyVM.history
        .where((e) => e.templateId == templateId)
        .toList();
    if (templateEntries.isEmpty) return const [];

    for (final entry in templateEntries.reversed) {
      final exLogs = entry.logs.where((l) => l.exerciseId == exerciseId);
      if (exLogs.isEmpty) continue;

      final sets = exLogs.last.sets;
      if (sets.isEmpty) continue;

      return List<PerformedSet>.from(sets);
    }

    return const [];
  }

  int _workNumberAtPlanned(List<PlannedSet> sets, int index) {
    int c = 0;
    for (int i = 0; i <= index; i++) {
      if (sets[i].type == SetType.work) c++;
    }
    return c == 0 ? 1 : c;
  }

  Color _typeColor(BuildContext ctx, SetType type) {
    final cs = Theme.of(ctx).colorScheme;
    return type == SetType.work
        ? cs.primary
        : type == SetType.warmup
        ? Colors.orange
        : Colors.purple;
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
      if (log == null) return;

      // Only auto-load if there’s no plan yet
      if (log.plannedSets.isNotEmpty) return;

      final historyVM = context.read<HistoryViewModel>();
      final lastSets = _lastWorkoutSetsForExercise(
        historyVM: historyVM,
        templateId: widget.templateId,
        exerciseId: widget.exercise.id,
      );

      if (lastSets.isEmpty) {
        // no history -> create 1 empty work row
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
  Widget build(BuildContext context) {
    final session = context.watch<WorkoutSessionViewModel>();
    final log = session.logs[widget.exercise.id];

    final planned = log?.plannedSets ?? <PlannedSet>[];
    final doneCount = planned.where((p) => p.done).length;

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

                  String label;
                  if (p.type == SetType.warmup) {
                    label = 'W';
                  } else if (p.type == SetType.dropset) {
                    label = 'D';
                  } else {
                    label = _workNumberAtPlanned(planned, i).toString();
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.6),
                      ),
                      color: p.done
                          ? cs.surfaceContainerHighest.withOpacity(0.25)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        _TypeBadge(
                          label: label,
                          color: _typeColor(context, p.type),
                          tooltip: p.type.name,
                          onTap: p.done
                              ? null
                              : () {
                                  final next = p.type == SetType.work
                                      ? SetType.warmup
                                      : p.type == SetType.warmup
                                      ? SetType.dropset
                                      : SetType.work;

                                  context
                                      .read<WorkoutSessionViewModel>()
                                      .updatePlannedSet(
                                        exerciseId: widget.exercise.id,
                                        index: i,
                                        type: next,
                                      );
                                },
                        ),
                        const SizedBox(width: 12),

                        // Weight
                        Expanded(
                          child: TextFormField(
                            initialValue: p.weight?.toString(),
                            enabled: !p.done,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'kg',
                            ),
                            onChanged: (v) {
                              final w = double.tryParse(
                                v.trim().replaceAll(',', '.'),
                              );
                              context
                                  .read<WorkoutSessionViewModel>()
                                  .updatePlannedSet(
                                    exerciseId: widget.exercise.id,
                                    index: i,
                                    weight: w,
                                  );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Reps
                        Expanded(
                          child: TextFormField(
                            initialValue: p.reps?.toString(),
                            enabled: !p.done,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'reps',
                            ),
                            onChanged: (v) {
                              final r = int.tryParse(v.trim());
                              context
                                  .read<WorkoutSessionViewModel>()
                                  .updatePlannedSet(
                                    exerciseId: widget.exercise.id,
                                    index: i,
                                    reps: r,
                                  );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        if (!p.done)
                          IconButton(
                            tooltip: 'Remove row',
                            icon: Icon(
                              Icons.delete_outline,
                              color: cs.onSurfaceVariant,
                            ),
                            onPressed: () => context
                                .read<WorkoutSessionViewModel>()
                                .removePlannedSetRow(
                                  exerciseId: widget.exercise.id,
                                  index: i,
                                ),
                          )
                        else
                          const SizedBox(width: 48),

                        FilledButton(
                          onPressed: p.done
                              ? null
                              : () {
                                  context
                                      .read<WorkoutSessionViewModel>()
                                      .markPlannedSetDone(
                                        exerciseId: widget.exercise.id,
                                        index: i,
                                      );
                                },
                          child: Text(p.done ? 'Done' : 'Add'),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 12),

            // Add new planned row
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

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final String? tooltip;
  final VoidCallback? onTap;

  const _TypeBadge({
    required this.label,
    required this.color,
    this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.6),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );

    return tooltip == null ? badge : Tooltip(message: tooltip!, child: badge);
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
