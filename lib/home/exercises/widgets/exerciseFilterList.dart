// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseTile.dart';

/// Filterable exercise list: a horizontal category chip rail on top,
/// followed by either a grouped ("All") or filtered list of exercises.
class ExerciseFilterList extends StatefulWidget {
  final List<ExerciseModel> exercises;
  final Set<ExerciseModel>? selectedExercises;
  final Function(ExerciseModel)? onExerciseTap;

  /// Extra space at the bottom of the scroll list so the last item isn't
  /// hidden behind fixed UI (e.g., a save button).
  final double bottomPadding;

  const ExerciseFilterList({
    super.key,
    required this.exercises,
    this.selectedExercises,
    this.onExerciseTap,
    this.bottomPadding = 0,
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
        // ── Category chip rail ─────────────────────────────────────
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              _CategoryChip(
                label: 'All',
                isSelected: _selectedCategory == null,
                onTap: () => setState(() => _selectedCategory = null),
              ),
              ...categories.map(
                (cat) => _CategoryChip(
                  label: cat.displayName,
                  iconAsset: cat.icon,
                  isSelected: _selectedCategory == cat,
                  onTap: () => setState(() => _selectedCategory = cat),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // ── Exercise list ──────────────────────────────────────────
        Expanded(
          child: _selectedCategory == null
              ? _buildGroupedList()
              : _buildFilteredList(),
        ),
      ],
    );
  }

  Widget _buildFilteredList() {
    final list = filteredExercises;
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'No exercises fit the current search\nand category filter.',
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(top: 4, bottom: widget.bottomPadding + 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final ex = list[index];
        return ExerciseTile(
          exercise: ex,
          isSelected: widget.selectedExercises?.contains(ex) ?? false,
          onSelected: widget.onExerciseTap,
        );
      },
    );
  }

  Widget _buildGroupedList() {
    if (widget.exercises.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'No exercises fit the current search.',
      );
    }

    final grouped = <WorkoutCategory, List<ExerciseModel>>{};
    for (var ex in widget.exercises) {
      grouped.putIfAbsent(ex.category, () => []).add(ex);
    }

    return ListView(
      padding: EdgeInsets.only(top: 4, bottom: widget.bottomPadding + 8),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
              child: SectionHeader(
                title: entry.key.displayName,
                trailing: Text(
                  '${entry.value.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                padding: EdgeInsets.zero,
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.iconAsset,
  });

  final String label;
  final String? iconAsset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: isSelected ? AppGradients.volt : null,
            color: isSelected ? null : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : cs.outlineVariant.withValues(alpha: 0.9),
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: AppColors.voltDeep.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconAsset != null) ...[
                Image.asset(
                  iconAsset!,
                  width: 18,
                  height: 18,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 6),
              ] else ...[
                Icon(
                  Icons.all_inclusive_rounded,
                  size: 15,
                  color: isSelected ? Colors.white : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
