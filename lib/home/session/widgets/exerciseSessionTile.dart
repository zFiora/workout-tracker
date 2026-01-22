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

  // Controllers keyed by "exerciseId:index"
  final Map<String, TextEditingController> _wCtrls = {};
  final Map<String, TextEditingController> _rCtrls = {};

  // Mark controllers that were initialized from the model once.
  final Set<String> _initialized = {};

  // Which planned rows are currently in "edit mode" (only for done rows)
  final Set<String> _editingKeys = {};

  String _k(int exerciseId, int index) => '$exerciseId:$index';

  TextEditingController _wc(int exerciseId, int index) =>
      _wCtrls.putIfAbsent(_k(exerciseId, index), () => TextEditingController());

  TextEditingController _rc(int exerciseId, int index) =>
      _rCtrls.putIfAbsent(_k(exerciseId, index), () => TextEditingController());

  void _initControllersOnce({
    required int exerciseId,
    required int index,
    required PlannedSet p,
  }) {
    final key = _k(exerciseId, index);
    if (_initialized.contains(key)) return;

    final wCtrl = _wc(exerciseId, index);
    final rCtrl = _rc(exerciseId, index);

    wCtrl.text = p.weight == null ? '' : p.weight!.toString();
    rCtrl.text = p.reps == null ? '' : p.reps!.toString();

    _initialized.add(key);
  }

  void _cleanupControllers(int exerciseId, int plannedLength) {
    final validKeys = <String>{};
    for (int i = 0; i < plannedLength; i++) {
      validKeys.add(_k(exerciseId, i));
    }

    final toRemove = _wCtrls.keys
        .where((k) => k.startsWith('$exerciseId:') && !validKeys.contains(k))
        .toList();

    for (final k in toRemove) {
      _wCtrls.remove(k)?.dispose();
      _rCtrls.remove(k)?.dispose();
      _editingKeys.remove(k);
      _initialized.remove(k);
    }
  }

  // ---------- history preload ----------

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

    // Pick the most recent workout by endedAt (fallback to startedAt).
    templateEntries.sort((a, b) {
      final aTime = a.endedAt ?? a.startedAt;
      final bTime = b.endedAt ?? b.startedAt;
      return bTime.compareTo(aTime);
    });

    for (final entry in templateEntries) {
      final exLog = entry.logs.cast<ExerciseLog?>().firstWhere(
        (l) => l?.exerciseId == exerciseId,
        orElse: () => null,
      );

      final sets = exLog?.sets ?? const <PerformedSet>[];
      if (sets.isNotEmpty) return List<PerformedSet>.from(sets);
    }

    return const [];
  }

  // ---------- UI helpers ----------

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
    for (final c in _wCtrls.values) {
      c.dispose();
    }
    for (final c in _rCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<WorkoutSessionViewModel>();
    final log = session.logs[widget.exercise.id];

    final planned = log?.plannedSets ?? <PlannedSet>[];
    final doneCount = planned.where((p) => p.done).length;

    final cs = Theme.of(context).colorScheme;

    _cleanupControllers(widget.exercise.id, planned.length);

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
                  final key = _k(widget.exercise.id, i);

                  _initControllersOnce(
                    exerciseId: widget.exercise.id,
                    index: i,
                    p: p,
                  );

                  final wCtrl = _wc(widget.exercise.id, i);
                  final rCtrl = _rc(widget.exercise.id, i);

                  final isEditing = _editingKeys.contains(key);
                  final isLocked = p.done && !isEditing;
                  final prHit = session.prHitForPlannedRow(
                    exerciseId: widget.exercise.id,
                    index: i,
                  );

                  final allowEdit = !p.done || isEditing;

                  String label;
                  if (p.type == SetType.warmup) {
                    label = 'W';
                  } else if (p.type == SetType.dropset) {
                    label = 'D';
                  } else {
                    label = _workNumberAtPlanned(planned, i).toString();
                  }

                  void showInvalidSnack() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter valid weight and reps'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  void commitToModel() {
                    final w = double.tryParse(
                      wCtrl.text.trim().replaceAll(',', '.'),
                    );
                    final r = int.tryParse(rCtrl.text.trim());

                    if (w == null || r == null) {
                      showInvalidSnack();
                      return;
                    }

                    context.read<WorkoutSessionViewModel>().updatePlannedSet(
                      exerciseId: widget.exercise.id,
                      index: i,
                      weight: w,
                      reps: r,
                    );
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
                          onTap: allowEdit
                              ? () {
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
                                }
                              : null,
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: TextField(
                            controller: wCtrl,
                            enabled: allowEdit,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'kg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: TextField(
                            controller: rCtrl,
                            enabled: allowEdit,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'reps',
                            ),
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
                        else if (!isEditing)
                          IconButton(
                            tooltip: 'Modify',
                            icon: Icon(
                              Icons.edit_outlined,
                              color: cs.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() => _editingKeys.add(key));
                            },
                          )
                        else
                          IconButton(
                            tooltip: 'Cancel',
                            icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                            onPressed: () {
                              // Revert controllers to the model values, then lock.
                              wCtrl.text = p.weight == null
                                  ? ''
                                  : p.weight!.toString();
                              rCtrl.text = p.reps == null
                                  ? ''
                                  : p.reps!.toString();

                              setState(() => _editingKeys.remove(key));
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        if (prHit != null) ...[
                          const SizedBox(width: 8),
                          const _PrPill(text: 'NEW PR'),
                          const SizedBox(width: 8),
                        ],

                        FilledButton(
                          onPressed: isLocked
                              ? null
                              : () {
                                  // Add: commit values then mark done
                                  if (!p.done) {
                                    commitToModel();
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

                                  // Save: commit values then lock again
                                  commitToModel();
                                  setState(() => _editingKeys.remove(key));
                                  FocusScope.of(context).unfocus();
                                },
                          child: Text(
                            !p.done ? 'Add' : (isEditing ? 'Save' : 'Done'),
                          ),
                        ),
                      ],
                    ),
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

class _PrPill extends StatefulWidget {
  final String text;
  const _PrPill({required this.text});

  @override
  State<_PrPill> createState() => _PrPillState();
}

class _PrPillState extends State<_PrPill> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutBack,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.primary.withOpacity(0.35)),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
