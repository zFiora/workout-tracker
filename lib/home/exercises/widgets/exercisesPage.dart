// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomSearchField.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/widgets/customExerciseEditorPage.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseFilterList.dart';
import 'package:workout_tracker/home/history/exDetail/exDetailPage.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  String _query = '';
  String? _equipment; // null = all equipment

  // Tapping an exercise opens its detail page (info, PRs, progress, history,
  // notes). The leaderboard lives as an action inside that page.
  void _openDetail(ExerciseModel exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailPage(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
        ),
      ),
    );
  }

  Future<void> _createExercise() async {
    final created = await Navigator.of(context).push<ExerciseModel>(
      MaterialPageRoute(builder: (_) => const CustomExerciseEditorPage()),
    );
    if (created != null && mounted) {
      setState(() {}); // catalog now includes the new custom exercise
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ExercisesViewModel.all;

    // Equipment options present in the catalog (for the filter rail).
    final equipmentOptions = <String>{for (final e in all) e.resolvedEquipment}
        .toList()
      ..sort();

    final q = _query.trim().toLowerCase();
    final filtered = all.where((e) {
      final matchesName = q.isEmpty || e.name.toLowerCase().contains(q);
      final matchesEquipment =
          _equipment == null || e.resolvedEquipment == _equipment;
      return matchesName && matchesEquipment;
    }).toList();

    return MyCustomeScaffoldView(
      title: 'Exercises',
      navigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: VoltButton(
            label: 'New Exercise',
            icon: Icons.add_rounded,
            onPressed: _createExercise,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: MyCustomSearchField(
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Equipment filter rail
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _EquipChip(
                  label: 'All equipment',
                  selected: _equipment == null,
                  onTap: () => setState(() => _equipment = null),
                ),
                for (final e in equipmentOptions)
                  _EquipChip(
                    label: e,
                    selected: _equipment == e,
                    onTap: () => setState(() => _equipment = e),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No exercises',
                    message:
                        'Nothing matches your search and filters.\nTry clearing them, or create a custom exercise.',
                  )
                : ExerciseFilterList(
                    exercises: filtered,
                    onExerciseOpen: _openDetail,
                  ),
          ),
        ],
      ),
    );
  }
}

class _EquipChip extends StatelessWidget {
  const _EquipChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? cs.onPrimary : cs.onSurface,
        ),
        selectedColor: cs.primary,
        backgroundColor: cs.surfaceContainerHigh,
        side: BorderSide(
          color: selected ? Colors.transparent : cs.outlineVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
