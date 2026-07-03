// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';

/// List tile for an exercise. Fully theme-aware (works in both dark and
/// light mode), with a press scale micro-interaction and an animated
/// selection state used by the template builder.
class ExerciseTile extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback? onTap;
  final bool isSelected;
  final Function(ExerciseModel)? onSelected;

  const ExerciseTile({
    super.key,
    required this.exercise,
    this.onTap,
    this.isSelected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = context.tokens;

    return Pressable(
      onTap: () {
        if (onSelected != null) {
          onSelected!(exercise); // selection mode
        } else if (onTap != null) {
          onTap!(); // normal tap
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.10)
              : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? cs.primary : tokens.cardBorder,
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: tokens.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Thumbnail with category tag ─────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.asset(
                    exercise.workoutImage,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 72,
                      height: 72,
                      color: cs.surfaceContainerHigh,
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      exercise.category.displayName,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            // ── Name + category ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Image.asset(
                        exercise.category.icon,
                        width: 15,
                        height: 15,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        exercise.category.displayName,
                        style: tt.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Selection indicator ─────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: isSelected
                  ? Container(
                      key: const ValueKey('sel'),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.volt,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    )
                  : (onSelected != null
                      ? Container(
                          key: const ValueKey('unsel'),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.outline, width: 1.6),
                          ),
                        )
                      : (onTap != null
                          ? Icon(
                              Icons.chevron_right_rounded,
                              key: const ValueKey('chev'),
                              color: cs.onSurfaceVariant,
                            )
                          : const SizedBox.shrink(key: ValueKey('none')))),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
