import 'package:flutter/material.dart';
import 'package:workout_tracker/common/formatters/numberFormatter.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/simpleCard.dart';
import 'package:workout_tracker/home/history/exDetail/exDetailViewModel.dart';
import 'package:workout_tracker/home/history/utils/strengthUtils.dart';

class LastSessionsCard extends StatelessWidget {
  const LastSessionsCard({super.key, required this.vm});
  final ExerciseDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final s = vm.last5;

    if (s.isEmpty) {
      return const SimpleCard(title: "Last 5 sessions", value: "No sessions yet");
    }

    return Card(
      child: Column(
        children: [
          const SizedBox(height: 6),
          ...s.map((e) {
            return ListTile(
              dense: true,
              title: Text(ymd(e.day)),
              subtitle: Text("Vol ${round1(e.sessionVolume)}"),
              trailing: Text(
                "${round1(e.bestWeight)} kg",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            );
          }).toList(),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
