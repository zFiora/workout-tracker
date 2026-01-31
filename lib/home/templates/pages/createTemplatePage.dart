import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomSearchField.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseFilterList.dart';
import 'package:workout_tracker/home/templates/widgets/templateSaveSheet.dart';

class CreateTemplatePage extends StatefulWidget {
  final List<ExerciseModel> exercises;

  const CreateTemplatePage({super.key, required this.exercises});

  @override
  State<CreateTemplatePage> createState() => _CreateTemplatePageState();
}

class _CreateTemplatePageState extends State<CreateTemplatePage> {
  final Set<ExerciseModel> _selectedExercises = {};
  String _searchQuery = "";

  Future<void> _openSaveSummarySheet() async {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one exercise first.')),
      );
      return;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => TemplateSaveSheet(selectedExercises: _selectedExercises),
    );

    if (!mounted) return;

    if (saved == true) {
      Navigator.pop(context); // close page after successful save
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = widget.exercises
        .where(
          (ex) => ex.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    final bottomSafe = MediaQuery.of(context).padding.bottom;

    const saveButtonHeight = 56.0;
    const saveButtonGap = 12.0;
    final listBottomPadding =
        saveButtonHeight + (saveButtonGap * 2) + bottomSafe;

    return MyCustomeScaffoldView(
      title: 'Create Template',
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SafeArea(
          child: Column(
            children: [
              MyCustomSearchField(
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 48.0,
                child: _selectedExercises.isEmpty
                    ? const Chip(label: Text('Selected Workouts'))
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _selectedExercises
                                .map(
                                  (ex) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Chip(label: Text(ex.name)),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ExerciseFilterList(
                  exercises: filteredExercises,
                  selectedExercises: _selectedExercises,
                  onExerciseTap: (ex) {
                    setState(() {
                      if (_selectedExercises.contains(ex)) {
                        _selectedExercises.remove(ex);
                      } else {
                        _selectedExercises.add(ex);
                      }
                    });
                  },
                  bottomPadding: listBottomPadding,
                ),
              ),

              const SizedBox(height: saveButtonGap),

              Padding(
                padding: const EdgeInsets.all(8),
                child: MyCustomButton(
                  onPressed: _openSaveSummarySheet,
                  fullWidth: true,
                  label: 'Save Template',
                  icon: Icons.add,
                  iconPosition: IconPosition.right,
                ),
              ),

              SizedBox(height: saveButtonGap + bottomSafe),
            ],
          ),
        ),
      ),
    );
  }
}
