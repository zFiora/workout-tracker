import 'package:flutter/material.dart';
import 'package:workout_tracker/home/history/exDetail/exDetailViewModel.dart';
import 'package:workout_tracker/home/history/repos/exHistoryRepo.dart';

class MetricToggle extends StatelessWidget {
  const MetricToggle({super.key, required this.vm});
  final ExerciseDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ChoiceChip(
          label: const Text("Best weight"),
          selected: vm.metric == ChartMetric.bestWeight,
          onSelected: (_) => vm.setMetric(ChartMetric.bestWeight),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text("Est 1RM"),
          selected: vm.metric == ChartMetric.bestEstimated1RM,
          onSelected: (_) => vm.setMetric(ChartMetric.bestEstimated1RM),
        ),
      ],
    );
  }
}
