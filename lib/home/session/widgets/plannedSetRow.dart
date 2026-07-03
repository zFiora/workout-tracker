import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
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

  int _workNumber(List<PlannedSet> sets, int idx) {
    int c = 0;
    for (int i = 0; i <= idx; i++) {
      if (sets[i].type == SetType.work) c++;
    }
    return c == 0 ? 1 : c;
  }

  Color _typeColor(BuildContext ctx, SetType type) {
    final cs = Theme.of(ctx).colorScheme;
    if (type == SetType.work) return cs.primary;
    if (type == SetType.warmup) return ctx.tokens.warning;
    return ctx.tokens.dropset;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = planned[index];
    final allowEdit = !p.done || isEditing;
    final isLocked = p.done && !isEditing;

    final typeColor = _typeColor(context, p.type);

    String label;
    if (p.type == SetType.warmup) {
      label = 'W';
    } else if (p.type == SetType.dropset) {
      label = 'D';
    } else {
      label = _workNumber(planned, index).toString();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.done
            ? context.tokens.success.withValues(alpha: 0.07)
            : cs.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(
          color: p.done
              ? context.tokens.success.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // ── Set type badge ────────────────────────────────────
          _TypeBadge(
            label: label,
            color: typeColor,
            tooltip: p.type.name,
            onTap: allowEdit ? onToggleType : null,
          ),
          const SizedBox(width: 10),

          // ── Weight input ──────────────────────────────────────
          Expanded(
            flex: 5,
            child: _NumberField(
              controller: weightController,
              enabled: allowEdit,
              unit: 'kg',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),

          // ── × separator ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '×',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),

          // ── Reps input ────────────────────────────────────────
          Expanded(
            flex: 4,
            child: _NumberField(
              controller: repsController,
              enabled: allowEdit,
              unit: 'reps',
              keyboardType: TextInputType.number,
            ),
          ),

          const SizedBox(width: 8),

          // ── PR tag (when this set hit a PR) ───────────────────
          if (prVisible) ...[const _PrTag(), const SizedBox(width: 6)],

          // ── Secondary icon: delete / edit / cancel ───────────
          if (!p.done)
            _TapIcon(
              icon: Icons.remove_circle_outline_rounded,
              color: cs.error.withValues(alpha: 0.7),
              onTap: onRemove,
            )
          else if (!isEditing)
            _TapIcon(
              icon: Icons.edit_outlined,
              color: cs.onSurfaceVariant,
              onTap: () => setEditing(true),
            )
          else
            _TapIcon(
              icon: Icons.close_rounded,
              color: cs.onSurfaceVariant,
              onTap: onCancelEdit,
            ),

          const SizedBox(width: 8),

          // ── Primary action: log / save ────────────────────────
          _LogButton(
            isDone: p.done && !isEditing,
            isEditing: isEditing && p.done,
            onTap: isLocked ? null : onAddOrSave,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Compact number field: center-aligned bold value with unit suffix.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.enabled,
    required this.unit,
    required this.keyboardType,
  });

  final TextEditingController controller;
  final bool enabled;
  final String unit;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: enabled
            ? cs.surface
            : cs.surfaceContainerHighest.withValues(alpha: 0.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        suffixText: unit,
        suffixStyle: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Circular log button — replaces the old FilledButton("Add"/"Done"/"Save").
class _LogButton extends StatelessWidget {
  const _LogButton({
    required this.isDone,
    required this.isEditing,
    required this.onTap,
  });

  final bool isDone;
  final bool isEditing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Already done and not being re-edited → solid green check (non-interactive)
    if (isDone) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.tokens.success,
          boxShadow: [
            BoxShadow(
              color: context.tokens.success.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
      );
    }

    // Done row in edit mode → save icon
    if (isEditing) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary.withValues(alpha: 0.1),
            border: Border.all(color: cs.primary, width: 1.5),
          ),
          child: Icon(Icons.save_rounded, color: cs.primary, size: 20),
        ),
      );
    }

    // Default: log this set
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primary.withValues(alpha: 0.08),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Icon(Icons.check_rounded, color: cs.primary, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Small icon tap target — avoids the 48px minimum of IconButton.
class _TapIcon extends StatelessWidget {
  const _TapIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Compact animated "PR" tag shown when a set breaks a personal record.
class _PrTag extends StatefulWidget {
  const _PrTag();

  @override
  State<_PrTag> createState() => _PrTagState();
}

class _PrTagState extends State<_PrTag> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
        ),
        child: Text(
          'PR',
          style: TextStyle(
            color: cs.onPrimaryContainer,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Set number / type badge — unchanged from the original, it works well.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.label,
    required this.color,
    this.tooltip,
    this.onTap,
  });

  final String label;
  final Color color;
  final String? tooltip;
  final VoidCallback? onTap;

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
