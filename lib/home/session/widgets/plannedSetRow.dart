import 'package:flutter/material.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class PlannedSetRow extends StatelessWidget {
  const PlannedSetRow({
    super.key,
    required this.exercise,
    required this.planned,
    required this.index,
    required this.rowKey,
    required this.weightController,
    required this.repsController,
    required this.isEditing,
    required this.setEditing,
    required this.prVisible,
    required this.onToggleType,
    required this.onRemove,
    required this.onAddOrSave,
    required this.onCancelEdit,
  });

  final ExerciseModel exercise;
  final List<PlannedSet> planned;
  final int index;
  final String rowKey;

  final TextEditingController weightController;
  final TextEditingController repsController;

  final bool isEditing;
  final void Function(bool editing) setEditing;

  final bool prVisible;

  final VoidCallback onToggleType;
  final VoidCallback? onRemove;
  final VoidCallback onAddOrSave;
  final VoidCallback onCancelEdit;

  int _workNumberAtPlanned(List<PlannedSet> sets, int idx) {
    int c = 0;
    for (int i = 0; i <= idx; i++) {
      if (sets[i].type == SetType.work) c++;
    }
    return c == 0 ? 1 : c;
  }

  Color _typeColor(BuildContext ctx, SetType type) {
    final cs = Theme.of(ctx).colorScheme;
    if (type == SetType.work) return cs.primary;
    if (type == SetType.warmup) return Colors.orange;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final p = planned[index];
    final allowEdit = !p.done || isEditing;
    final isLocked = p.done && !isEditing;

    String label;
    if (p.type == SetType.warmup) {
      label = 'W';
    } else if (p.type == SetType.dropset) {
      label = 'D';
    } else {
      label = _workNumberAtPlanned(planned, index).toString();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
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
            onTap: allowEdit ? onToggleType : null,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: TextField(
              controller: weightController,
              enabled: allowEdit,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(isDense: true, labelText: 'kg'),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: repsController,
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
              icon: Icon(Icons.delete_outline, color: cs.onSurfaceVariant),
              onPressed: onRemove,
            )
          else if (!isEditing)
            IconButton(
              tooltip: 'Modify',
              icon: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant),
              onPressed: () => setEditing(true),
            )
          else
            IconButton(
              tooltip: 'Cancel',
              icon: Icon(Icons.close, color: cs.onSurfaceVariant),
              onPressed: onCancelEdit,
            ),

          if (prVisible) ...[
            const SizedBox(width: 8),
            const _PrPill(text: 'NEW PR'),
            const SizedBox(width: 8),
          ],

          FilledButton(
            onPressed: isLocked ? null : onAddOrSave,
            child: Text(!p.done ? 'Add' : (isEditing ? 'Save' : 'Done')),
          ),
        ],
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
