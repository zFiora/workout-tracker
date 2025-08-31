import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomSearchField.dart';
import 'package:workout_tracker/common/widgets/myCustomTextField.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseFilterList.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';
import 'package:workout_tracker/home/templates/templatesViewModel.dart';
import 'package:provider/provider.dart';

class CreateTemplatePage extends StatefulWidget {
  final List<ExerciseModel> exercises;

  const CreateTemplatePage({super.key, required this.exercises});

  @override
  State<CreateTemplatePage> createState() => _CreateTemplatePageState();
}

class _CreateTemplatePageState extends State<CreateTemplatePage> {
  final _nameController = TextEditingController();
  String? _selectedIconPath;
  final Set<ExerciseModel> _selectedExercises = {};
  String _searchQuery = "";
  final ScrollController _scrollController = ScrollController();

  // Keys for scrolling
  final _nameKey = GlobalKey();
  final _iconKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = widget.exercises
        .where(
          (ex) => ex.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("New Template")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Template Name
                      Container(
                        key: _nameKey,
                        child: MyCustomTextField(
                          controller: _nameController,
                          hint: "Template Name",
                          icon: Icons.text_fields,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Icon selector
                      Container(
                        key: _iconKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select an Icon",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 80,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                children: [
                                  _iconTile(
                                    "assets/workout_category/chest_emoji.png",
                                  ),
                                  _iconTile(
                                    "assets/workout_category/abs_emoji.png",
                                  ),
                                  _iconTile(
                                    "assets/workout_category/back_emoji.png",
                                  ),
                                  _iconTile(
                                    "assets/workout_category/shoulders_emoji.png",
                                  ),
                                  _iconTile(
                                    "assets/workout_category/tricep_emoji.png",
                                  ),
                                  _iconTile(
                                    "assets/workout_category/bicep_emoji.png",
                                  ),
                                  _iconTile(
                                    "assets/workout_category/cardio_emoji.png",
                                  ),
                                  _iconTile(
                                    "assets/workout_category/legs_emoji.png",
                                  ),
                                  _iconTile(
                                    "assets/workout_category/forearms_emoji.png",
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search bar
                      MyCustomSearchField(
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Selected exercises
                      if (_selectedExercises.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedExercises
                              .map((ex) => Chip(label: Text(ex.name)))
                              .toList(),
                        ),
                      if (_selectedExercises.isNotEmpty)
                        const SizedBox(height: 16),

                      // Exercise picker
                      SizedBox(
                        height: 500,
                        child: ExerciseFilterList(
                          exercises: filteredExercises,
                          onExerciseTap: (ex) {
                            setState(() {
                              if (_selectedExercises.contains(ex)) {
                                _selectedExercises.remove(ex);
                              } else {
                                _selectedExercises.add(ex);
                              }
                            });
                          },
                          selectedExercises: _selectedExercises,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Save button
              Center(
                child: MyCustomButton(
                  label: "Save Template",
                  onPressed: () {
                    _saveTemplate();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconTile(String path) {
    final primary = Theme.of(context).colorScheme.primary;
    final surfaceVariant = Theme.of(context).colorScheme.surfaceVariant;
    final selected = path == _selectedIconPath;
    return GestureDetector(
      onTap: () => setState(() => _selectedIconPath = path),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? primary : surfaceVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(path, width: 60, height: 60),
      ),
    );
  }

  void _saveTemplate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty ||
        _selectedIconPath == null ||
        _selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            decoration: BoxDecoration(color: Colors.red),
            child: Text(
              'Please enter a name, pick an icon, and select at least one exercise.',
            ),
          ),
        ),
      );
      return;
    }

    // Build exercise IDs only
    final List<int> exerciseIds = _selectedExercises
        .map((ExerciseModel e) => e.id)
        .toList();

    // Create Hive model
    final template = WorkoutTemplateModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      iconPath: _selectedIconPath!,
      exerciseIds: exerciseIds,
    );

    // Persist via ViewModel (Hive-backed)
    await context.read<TemplatesViewModel>().addTemplate(template);

    Navigator.pop(context);
  }
}
