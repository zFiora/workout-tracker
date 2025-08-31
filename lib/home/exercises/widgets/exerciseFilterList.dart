// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseTile.dart';

class ExerciseFilterList extends StatefulWidget {
  final List<ExerciseModel> exercises;
  final Set<ExerciseModel>? selectedExercises;
  final Function(ExerciseModel)? onExerciseTap;
  const ExerciseFilterList({
    super.key,
    required this.exercises,
    this.selectedExercises,
    this.onExerciseTap,
  });

  @override
  State<ExerciseFilterList> createState() => _ExerciseFilterListState();
}

class _ExerciseFilterListState extends State<ExerciseFilterList> {
  WorkoutCategory? _selectedCategory; // null = all

  List<WorkoutCategory> get categories {
    final catSet = widget.exercises.map((e) => e.category).toSet().toList();
    catSet.sort((a, b) => a.displayName.compareTo(b.displayName));
    return catSet;
  }

  List<ExerciseModel> get filteredExercises {
    if (_selectedCategory == null) return widget.exercises;
    return widget.exercises
        .where((e) => e.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // FILTER TILES ROW
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              _buildFilterTile(
                label: "All",
                icon: Icons.all_inclusive,
                isSelected: _selectedCategory == null,
                onTap: () => setState(() => _selectedCategory = null),
              ),
              ...categories.map((cat) {
                return _buildFilterTile(
                  label: cat.displayName,
                  iconAsset: cat.icon,
                  isSelected: _selectedCategory == cat,
                  onTap: () => setState(() => _selectedCategory = cat),
                );
              }),
            ],
          ),
        ),

        // EXERCISES LIST
        Expanded(
          child: _selectedCategory == null
              ? _buildGroupedList()
              : _buildFilteredList(),
        ),
      ],
    );
  }

  Widget _buildFilterTile({
    required String label,
    String? iconAsset,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    final surfaceVariant = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            color: isSelected ? primary : surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (isSelected)
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconAsset != null)
                Image.asset(iconAsset, width: 32, height: 32)
              else if (icon != null)
                Icon(
                  icon,
                  size: 32,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredList() {
    return ListView.builder(
      itemCount: filteredExercises.length,
      itemBuilder: (context, index) {
        final ex = filteredExercises[index];
        return ExerciseTile(
          exercise: ex,
          isSelected: widget.selectedExercises?.contains(ex) ?? false,
          onSelected: widget.onExerciseTap,
        );
      },
    );
  }

  Widget _buildGroupedList() {
    final grouped = <WorkoutCategory, List<ExerciseModel>>{};
    for (var ex in widget.exercises) {
      grouped.putIfAbsent(ex.category, () => []).add(ex);
    }

    return ListView(
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                entry.key.displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...entry.value.map(
              (ex) => ExerciseTile(
                exercise: ex,
                isSelected: widget.selectedExercises?.contains(ex) ?? false,
                onSelected: widget.onExerciseTap,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
