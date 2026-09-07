import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/reorder_support.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';

/// A dedicated, compact surface for reordering a workout's exercises.
///
/// Reordering the live session cards directly is what caused the broken
/// "giant gray box" drag — those cards are tall, expanded, and hold live
/// inputs. Here each exercise is a small fixed-height row, so the drag
/// feedback and the gap it leaves behind stay tidy and the interaction is
/// smooth. Only display order changes; logged sets (keyed by exercise id in
/// the session view-model) are never touched.
class ReorderExercisesSheet extends StatefulWidget {
  const ReorderExercisesSheet({
    super.key,
    required this.exercises,
    required this.onReorder,
  });

  final List<ExerciseModel> exercises;
  final void Function(int oldIndex, int newIndex) onReorder;

  static Future<void> show(
    BuildContext context, {
    required List<ExerciseModel> exercises,
    required void Function(int oldIndex, int newIndex) onReorder,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ReorderExercisesSheet(exercises: exercises, onReorder: onReorder),
    );
  }

  @override
  State<ReorderExercisesSheet> createState() => _ReorderExercisesSheetState();
}

class _ReorderExercisesSheetState extends State<ReorderExercisesSheet> {
  late List<ExerciseModel> _items = List.of(widget.exercises);

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      var target = newIndex;
      if (target > oldIndex) target -= 1;
      final moved = _items.removeAt(oldIndex);
      _items.insert(target, moved);
    });
    widget.onReorder(oldIndex, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.72;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 60, 0, 0),
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor ?? cs.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Reorder exercises'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Drag the handle to change the order. Your logged sets stay put.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
              buildDefaultDragHandles: false,
              proxyDecorator: liftProxyDecorator,
              itemCount: _items.length,
              onReorder: _reorder,
              itemBuilder: (context, i) {
                final ex = _items[i];
                return _ReorderRow(
                  key: ValueKey(ex.id),
                  index: i,
                  position: i + 1,
                  exercise: ex,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReorderRow extends StatelessWidget {
  const _ReorderRow({
    required super.key,
    required this.index,
    required this.position,
    required this.exercise,
  });

  final int index;
  final int position;
  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$position',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                exercise.workoutImage,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  color: cs.surfaceContainerHigh,
                  child: Icon(Icons.fitness_center_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                exercise.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                child: Icon(Icons.drag_indicator_rounded,
                    color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
