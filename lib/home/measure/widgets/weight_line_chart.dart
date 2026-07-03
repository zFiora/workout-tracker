import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/measurement_entry.dart';
import 'package:intl/intl.dart';

class WeightLineChart extends StatelessWidget {
  const WeightLineChart({
    super.key,
    required this.entries,
  });

  final List<MeasurementEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return Center(
        child: Text(
          'Add at least 2 entries to see the graph',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].weightKg));
    }

    final minY =
        entries.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b) - 1;
    final maxY =
        entries.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b) + 1;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.6),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 42,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (entries.length / 4).clamp(1, 999),
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) {
                  return const SizedBox.shrink();
                }
                final date =
                    DateFormat('dd/MM').format(entries[idx].date.toLocal());
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(date, style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final e = entries[idx];
                return LineTooltipItem(
                  '${e.weightKg.toStringAsFixed(1)} kg\n'
                  '${DateFormat('EEE, dd MMM').format(e.date.toLocal())}',
                  TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3.5,
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
            ),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}
