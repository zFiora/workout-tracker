import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/units/weight_unit.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/simpleCard.dart';
import 'package:workout_tracker/home/history/exDetail/exDetailViewModel.dart';
import 'package:workout_tracker/home/history/utils/strengthUtils.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.vm});
  final ExerciseDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final unit = context.select<AppManager, WeightUnit>((m) => m.weightUnit);
    final best = vm.bestSet;
    final bestText = best == null
        ? "No data yet"
        : "${unit.formatWithUnit(best.weight)} × ${best.reps}  •  est 1RM ${unit.formatWithUnit(vm.bestSetEstimated1RM)}";

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: SimpleCard(title: "Best set (est 1RM)", value: bestText)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SimpleCard(
                title: "Weight PR",
                value: unit.formatWithUnit(vm.prs.bestWeight),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SimpleCard(
                title: "Rep PR",
                value: "${vm.prs.bestReps} reps",
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SimpleCard(
          title: "Volume PR (single set)",
          value: "${round1(vm.prs.bestSetVolume)}",
        ),
      ],
    );
  }
}
