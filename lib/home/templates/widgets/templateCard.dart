import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';

/// Grid card for a workout template: icon on a soft radial plate, bold
/// Space Grotesk name, exercise count. The icon flies to the detail page
/// via a Hero transition.
class TemplateCard extends StatelessWidget {
  const TemplateCard({super.key, required this.template, required this.onOpen});

  final WorkoutTemplateModel template;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = context.tokens;

    return Pressable(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: tokens.cardBorder),
          boxShadow: [
            BoxShadow(
              color: tokens.cardShadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'tpl-icon-${template.id}',
              child: Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.22),
                      cs.primary.withValues(alpha: 0.04),
                    ],
                  ),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Image.asset(
                  template.iconPath,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.fitness_center_rounded,
                    size: 36,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              template.name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: tt.titleLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              '${template.exerciseIds.length} '
              '${template.exerciseIds.length == 1 ? "exercise" : "exercises"}',
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
