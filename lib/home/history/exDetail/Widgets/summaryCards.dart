import 'package:flutter/material.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/simpleCard.dart';
import 'package:workout_tracker/home/history/exDetail/exDetailViewModel.dart';
import 'package:workout_tracker/home/history/utils/strengthUtils.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.vm});
  final ExerciseDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final best = vm.bestSet;
    final bestText = best == null
        ? "No data yet"
        : "${round1(best.weight)} kg × ${best.reps}  •  est 1RM ${round1(vm.bestSetEstimated1RM)} kg";

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
                value: "${round1(vm.prs.bestWeight)} kg",
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
