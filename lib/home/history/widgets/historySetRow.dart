import 'package:flutter/material.dart';
import 'package:workout_tracker/home/history/widgets/historyBadges.dart';


class HistorySetRow extends StatelessWidget {
  const HistorySetRow({
    super.key,
    required this.leftLabel,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeFg,
    required this.mainText,
    required this.subText,
    required this.showPr,
  });

  final String leftLabel;
  final String badgeText;
  final Color badgeBg;
  final Color badgeFg;
  final String mainText;
  final String subText;
  final bool showPr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 66,
          child: Text(
            leftLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SetTypeBadge(text: badgeText, bg: badgeBg, fg: badgeFg),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  mainText,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showPr) ...[
                const SizedBox(width: 8),
                PrBadge(bg: cs.primaryContainer, fg: cs.onPrimaryContainer),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          subText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.65),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
