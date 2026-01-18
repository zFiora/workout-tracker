import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/history/exDetail/exDetailViewModel.dart';
import 'package:workout_tracker/home/history/models/exNote.dart';
import 'package:workout_tracker/home/history/repos/exHistoryRepo.dart';
import 'package:workout_tracker/home/history/utils/strengthUtils.dart';

import '../../session/models/sessionModels.dart';

class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  final int exerciseId;
  final String exerciseName;

  @override
  Widget build(BuildContext context) {
    final historyBox = Hive.box<WorkoutHistoryEntry>('historyBox');
    final notesBox = Hive.box<ExerciseNote>('exerciseNotesBox');

    return ChangeNotifierProvider(
      create: (_) => ExerciseDetailViewModel(
        exerciseId: exerciseId,
        historyRepo: ExerciseHistoryRepository(historyBox),
        notesBox: notesBox,
      ),
      child: _ExerciseDetailView(exerciseName: exerciseName),
    );
  }
}

class _ExerciseDetailView extends StatelessWidget {
  const _ExerciseDetailView({required this.exerciseName});
  final String exerciseName;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExerciseDetailViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(exerciseName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCards(vm: vm),
          const SizedBox(height: 12),
          _MetricToggle(vm: vm),
          const SizedBox(height: 8),
          _MiniSeries(series: vm.series),
          const SizedBox(height: 16),
          _LastSessions(vm: vm),
          const SizedBox(height: 16),
          _Notes(vm: vm),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.vm});
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
            Expanded(
              child: _Card(
                title: "Best set (est 1RM)",
                value: bestText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Card(
                title: "Weight PR",
                value: "${round1(vm.prs.bestWeight)} kg",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Card(
                title: "Rep PR",
                value: "${vm.prs.bestReps} reps",
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Card(
          title: "Volume PR (single set)",
          value: "${round1(vm.prs.bestSetVolume)}",
        ),
      ],
    );
  }
}

class _MetricToggle extends StatelessWidget {
  const _MetricToggle({required this.vm});
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

class _MiniSeries extends StatelessWidget {
  const _MiniSeries({required this.series});
  final List<(DateTime day, double value)> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const _Card(title: "Trend", value: "No chart data yet");
    }

    final values = series.map((e) => e.$2).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);

    return _Card(
      title: "Trend",
      valueWidget: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: series.map((p) {
          final norm = (p.$2 - minV) / span; // 0..1
          final h = 8 + (norm * 22); // 8..30
          return Container(
            width: 6,
            height: h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LastSessions extends StatelessWidget {
  const _LastSessions({required this.vm});
  final ExerciseDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final s = vm.last5;

    return _Card(
      title: "Last 5 sessions",
      valueWidget: s.isEmpty
          ? const Text("No sessions yet")
          : Column(
              children: s.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${e.day.year}-${e.day.month.toString().padLeft(2, '0')}-${e.day.day.toString().padLeft(2, '0')}",
                        ),
                      ),
                      Text("${round1(e.bestWeight)} kg"),
                      const SizedBox(width: 10),
                      Text("Vol ${round1(e.sessionVolume)}"),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _Notes extends StatefulWidget {
  const _Notes({required this.vm});
  final ExerciseDetailViewModel vm;

  @override
  State<_Notes> createState() => _NotesState();
}

class _NotesState extends State<_Notes> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    return _Card(
      title: "Notes",
      valueWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Add a note (form cues, pain, setup...)",
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  await vm.addNote(controller.text);
                  controller.clear();
                },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (vm.notes.isEmpty)
            const Text("No notes yet")
          else
            ...vm.notes.take(10).map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text("• ${n.text}"),
                )),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    String? value,
    Widget? valueWidget,
  })  : value = value,
        valueWidget = valueWidget;

  final String title;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (valueWidget != null)
            valueWidget!
          else
            Text(value ?? "-", style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
