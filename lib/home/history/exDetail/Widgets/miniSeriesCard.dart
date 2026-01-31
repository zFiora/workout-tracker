import 'package:flutter/material.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/simpleCard.dart';


class MiniSeriesCard extends StatelessWidget {
  const MiniSeriesCard({super.key, required this.series});
  final List<(DateTime day, double value)> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const SimpleCard(title: "Trend", value: "No chart data yet");
    }

    final values = series.map((e) => e.$2).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);

    final primary = Theme.of(context).colorScheme.primary;

    return SimpleCard(
      title: "Trend",
      valueWidget: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: series.map((p) {
          final norm = (p.$2 - minV) / span;
          final h = 8 + (norm * 22);
          return Container(
            width: 6,
            height: h,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }).toList(),
      ),
    );
  }
}
