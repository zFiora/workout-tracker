import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomSearchField.dart';
import 'package:workout_tracker/common/widgets/myCustomTextField.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseFilterList.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';

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

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
                    if (_nameController.text.isEmpty) {
                      _scrollToKey(_nameKey);
                      return;
                    }
                    if (_selectedIconPath == null) {
                      _scrollToKey(_iconKey);
                      return;
                    }
                    if (_selectedExercises.isEmpty) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      return;
                    }
          
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
    final selected = path == _selectedIconPath;
    return GestureDetector(
      onTap: () => setState(() => _selectedIconPath = path),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? Colors.teal : Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(path, width: 60, height: 60),
      ),
    );
  }

  void _saveTemplate() {
    final newTemplate = WorkoutTemplateModel(
      name: _nameController.text,
      iconPath: _selectedIconPath!,
      exercises: _selectedExercises.toList(),
    );

    Navigator.pop(context, newTemplate);
  }
}
