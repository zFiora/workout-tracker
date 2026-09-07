import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/units/weight_unit.dart';
import 'package:workout_tracker/home/history/exDetail/exDetailViewModel.dart';

class HeaderStatsCard extends StatelessWidget {
  const HeaderStatsCard({super.key, required this.vm});
  final ExerciseDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final unit = context.select<AppManager, WeightUnit>((m) => m.weightUnit);
    final best = vm.bestSet;
    final pr = vm.prs;

    final bestSetText = best == null
        ? "No data yet"
        : "${unit.formatWithUnit(best.weight)} × ${best.reps}";
    final bestMetricText = best == null
        ? "-"
        : "est 1RM ${unit.formatWithUnit(vm.bestSetEstimated1RM)}";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: _MiniStat(label: "Best set", value: bestSetText)),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat(label: "Top metric", value: bestMetricText)),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat(label: "Rep PR", value: "${pr.bestReps}")),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    final valueStyle = Theme.of(context).textTheme.titleSmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 4),
        Text(value, style: valueStyle),
      ],
    );
  }
}
