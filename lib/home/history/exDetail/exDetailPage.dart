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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            title: Text(exerciseName),
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
                child: _HeaderStats(vm: vm),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                const _SectionTitle(
                  icon: Icons.emoji_events,
                  title: "Personal Records",
                ),
                const SizedBox(height: 8),
                _SummaryCards(vm: vm),

                const SizedBox(height: 16),

                const _SectionTitle(icon: Icons.show_chart, title: "Progress"),
                const SizedBox(height: 8),
                _MetricToggle(vm: vm),
                const SizedBox(height: 8),
                _MiniSeries(series: vm.series),

                const SizedBox(height: 16),

                const _SectionTitle(
                  icon: Icons.history,
                  title: "Recent Sessions",
                ),
                const SizedBox(height: 8),
                _LastSessions(vm: vm),

                const SizedBox(height: 16),

                const _SectionTitle(icon: Icons.note_alt, title: "Notes"),
                const SizedBox(height: 8),
                _Notes(vm: vm),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 18, color: primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _HeaderStats extends StatelessWidget {
  const _HeaderStats({required this.vm});
  final ExerciseDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final best = vm.bestSet;
    final pr = vm.prs;

    final bestSetText = best == null
        ? "No data yet"
        : "${round1(best.weight)} kg × ${best.reps}";
    final bestMetricText = best == null
        ? "-"
        : "est 1RM ${round1(vm.bestSetEstimated1RM)} kg";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _MiniStat(label: "Best set", value: bestSetText),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(label: "Top metric", value: bestMetricText),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(label: "Rep PR", value: "${pr.bestReps}"),
            ),
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
              child: _Card(title: "Best set (est 1RM)", value: bestText),
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
              child: _Card(title: "Rep PR", value: "${vm.prs.bestReps} reps"),
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.85),
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

    if (s.isEmpty) {
      return const _Card(title: "Last 5 sessions", value: "No sessions yet");
    }

    return Card(
      child: Column(
        children: [
          const SizedBox(height: 6),
          ...s.map((e) {
            final date =
                "${e.day.year}-${e.day.month.toString().padLeft(2, '0')}-${e.day.day.toString().padLeft(2, '0')}";

            return ListTile(
              dense: true,
              title: Text(date),
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
    final canSend = controller.text.trim().isNotEmpty;

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
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: "Add a note (form cues, pain, setup...)",
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: canSend
                    ? () async {
                        final msg = controller.text.trim();
                        controller.clear();
                        setState(() {});

                        await vm.addNote(msg);
                        if (!mounted) return;
                        FocusScope.of(context).unfocus();
                      }
                    : null,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (vm.notes.isEmpty)
            const Text("No notes yet")
          else
            ...vm.notes
                .take(10)
                .map(
                  (n) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(n.text),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, String? value, Widget? valueWidget})
    : value = value,
      valueWidget = valueWidget;

  final String title;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
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
      ),
    );
  }
}
