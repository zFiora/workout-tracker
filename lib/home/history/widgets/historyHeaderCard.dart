import 'package:flutter/material.dart';

class HistoryHeaderCard extends StatelessWidget {
  const HistoryHeaderCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.chips,
  });

  final String iconPath;
  final String title;
  final String subtitle;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHigh.withValues(alpha: 0.75),
            cs.surfaceContainerHigh.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(color: cs.outline.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: cs.secondaryContainer.withValues(alpha: 0.55),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              iconPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.fitness_center,
                color: cs.onSecondaryContainer.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.75),
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10, children: chips),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
