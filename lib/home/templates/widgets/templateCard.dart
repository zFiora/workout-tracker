import 'package:flutter/material.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';

class TemplateCard extends StatelessWidget {
  const TemplateCard({super.key, required this.template, required this.onOpen});

  final WorkoutTemplateModel template;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              template.iconPath,
              width: 64,
              height: 64,
              errorBuilder: (_, _, _) => Icon(
                Icons.fitness_center,
                size: 56,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              template.name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${template.exerciseIds.length} exercises',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
