import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/sessionViewModel.dart';

class ExerciseSessionTile extends StatefulWidget {
  final ExerciseModel exercise;
  const ExerciseSessionTile({super.key, required this.exercise});

  @override
  State<ExerciseSessionTile> createState() => _ExerciseSessionTileState();
}

class _ExerciseSessionTileState extends State<ExerciseSessionTile> {
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  SetType _type = SetType.work;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _cycleType() {
    setState(() {
      switch (_type) {
        case SetType.work:
          _type = SetType.warmup;
          break;
        case SetType.warmup:
          _type = SetType.dropset;
          break;
        case SetType.dropset:
          _type = SetType.work;
          break;
      }
    });
  }

  String _typeShort(SetType type, {int? setNumber}) {
    if (type == SetType.work) return (setNumber ?? 1).toString();
    if (type == SetType.warmup) return 'W';
    return 'D';
  }

  Color _typeColor(BuildContext ctx, SetType type) {
    final cs = Theme.of(ctx).colorScheme;
    switch (type) {
      case SetType.work:
        return cs.primary;
      case SetType.warmup:
        return Colors.orange;
      case SetType.dropset:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<WorkoutSessionViewModel>();
    final log = session.logs[widget.exercise.id];
    int nextIndex = 1;
    for (var oneSet in log?.sets ?? []) {
      if (oneSet.type == SetType.work) {
        nextIndex++;
      }
      print(oneSet.type);
      print(
        "Set type: ${oneSet.type}, weight: ${oneSet.weight}, reps: ${oneSet.reps}",
      );
    }
    int setIndexing = 0;
    return ExpansionTile(
      leading: _ExerciseThumb(ex: widget.exercise),
      title: Text(widget.exercise.name),
      subtitle: Text('${log?.sets.length ?? 0} sets'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      maintainState: true,
      children: [
        // Existing sets
        if ((log?.sets.isNotEmpty ?? false))
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: log!.sets.length,
            itemBuilder: (_, index) {
              final s = log.sets[index];
              if (s.setType == SetType.work) {
                setIndexing++;
              }
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                // Leading badge for existing sets:
                leading: GestureDetector(
                  onTap: () {
                    // cycle type for the existing set
                    final next = s.type == SetType.work
                        ? SetType.warmup
                        : s.type == SetType.warmup
                        ? SetType.dropset
                        : SetType.work;
                    context.read<WorkoutSessionViewModel>().updateSetType(
                      exerciseId: widget.exercise.id,
                      index: index,
                      type: next,
                    );
                  },

                  child: _TypeBadge(
                    label: _typeShort(s.type, setNumber: setIndexing),
                    color: _typeColor(context, s.type),
                    tooltip: s.type.name,
                  ),
                ),
                title: Text(
                  'Set ${index + 1}: ${s.weight} kg  ×  ${s.reps} reps',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => context
                      .read<WorkoutSessionViewModel>()
                      .removeSet(widget.exercise.id, index),
                ),
              );
            },
          ),

        const SizedBox(height: 8),
        const Divider(height: 12),

        // Add new set form
        Form(
          key: _formKey,
          child: Row(
            children: [
              // LEFT BADGE: shows next set number or W/D, tap to cycle
              GestureDetector(
                onTap: _cycleType,
                child: _TypeBadge(
                  label: _typeShort(_type, setNumber: nextIndex),
                  color: _typeColor(context, _type),
                  tooltip: _type == SetType.work
                      ? 'Normal set'
                      : _type == SetType.warmup
                      ? 'Warm‑up'
                      : 'Drop set',
                ),
              ),
              const SizedBox(width: 12),

              // Weight
              Expanded(
                child: TextFormField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    isDense: true,
                  ),
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    if (d == null || d < 0) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Reps
              Expanded(
                child: TextFormField(
                  controller: _repsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    isDense: true,
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Add
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() != true) return;
                  final weight = double.parse(_weightCtrl.text.trim());
                  final reps = int.parse(_repsCtrl.text.trim());

                  context.read<WorkoutSessionViewModel>().addSet(
                    exerciseId: widget.exercise.id,
                    weight: weight,
                    reps: reps,
                    type: _type,
                  );

                  _weightCtrl.clear();
                  _repsCtrl.clear();
                  setState(() => _type = SetType.work);
                  FocusScope.of(context).unfocus();
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final String? tooltip;
  const _TypeBadge({required this.label, required this.color, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
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
    final String? path = (ex.workoutImage.isNotEmpty == true)
        ? ex.workoutImage
        : (ex.workoutImage.isNotEmpty == true)
        ? ex.workoutImage
        : null;

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
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
    );
  }
}
