import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/headerStatsCard.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/lastSessionCard.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/metricToggle.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/miniSeriesCard.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/notesCard.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/sectionTitle.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/summaryCards.dart';
import 'package:workout_tracker/home/history/exDetail/exDetailViewModel.dart';
import 'package:workout_tracker/home/history/models/exNote.dart';
import 'package:workout_tracker/home/history/repos/exHistoryRepo.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

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
                child: HeaderStatsCard(vm: vm),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                const SectionTitle(
                  icon: Icons.emoji_events,
                  title: "Personal Records",
                ),
                const SizedBox(height: 8),
                SummaryCards(vm: vm),

                const SizedBox(height: 16),

                const SectionTitle(icon: Icons.show_chart, title: "Progress"),
                const SizedBox(height: 8),
                MetricToggle(vm: vm),
                const SizedBox(height: 8),
                MiniSeriesCard(series: vm.series),

                const SizedBox(height: 16),

                const SectionTitle(
                  icon: Icons.history,
                  title: "Recent Sessions",
                ),
                const SizedBox(height: 8),
                LastSessionsCard(vm: vm),

                const SizedBox(height: 16),

                const SectionTitle(icon: Icons.note_alt, title: "Notes"),
                const SizedBox(height: 8),
                NotesCard(vm: vm),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
