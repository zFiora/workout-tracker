import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomSearchField.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseFilterList.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';
import 'package:workout_tracker/home/templates/templatesViewModel.dart';

class CreateTemplatePage extends StatefulWidget {
  final List<ExerciseModel> exercises;

  const CreateTemplatePage({super.key, required this.exercises});

  @override
  State<CreateTemplatePage> createState() => _CreateTemplatePageState();
}

class _CreateTemplatePageState extends State<CreateTemplatePage> {
  final Set<ExerciseModel> _selectedExercises = {};
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredExercises = widget.exercises
        .where(
          (ex) => ex.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    final bottomSafe = MediaQuery.of(context).padding.bottom;

    // Reserve space so the last list item scrolls above the Save button
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
              // Search
              MyCustomSearchField(
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 12),

              // Selected chips
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

              // List takes remaining space (NO fixed height -> no white space)
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

              // Save button (opens summary sheet)
              Padding(
                padding: const EdgeInsets.all(8.0),
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

  void _openSaveSummarySheet() {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one exercise first.')),
      );
      return;
    }

    final nameController = TextEditingController();
    String? selectedIconPath;

    final icons = <String>[
      "assets/workout_category/chest_emoji.png",
      "assets/workout_category/abs_emoji.png",
      "assets/workout_category/back_emoji.png",
      "assets/workout_category/shoulders_emoji.png",
      "assets/workout_category/tricep_emoji.png",
      "assets/workout_category/bicep_emoji.png",
      "assets/workout_category/cardio_emoji.png",
      "assets/workout_category/legs_emoji.png",
      "assets/workout_category/forearms_emoji.png",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom;

        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + bottomInset,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Review & Save",
                        style: Theme.of(sheetCtx).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: "Template Name",
                      prefixIcon: Icon(Icons.text_fields),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    "Pick an Icon",
                    style: Theme.of(sheetCtx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: icons.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final path = icons[i];
                        final selected = path == selectedIconPath;
                        final primary = Theme.of(sheetCtx).colorScheme.primary;
                        final outline = Theme.of(
                          sheetCtx,
                        ).colorScheme.outlineVariant;

                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedIconPath = path),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? primary : outline,
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(path),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    "Selected Exercises (${_selectedExercises.length})",
                    style: Theme.of(sheetCtx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedExercises
                            .map((ex) => Chip(label: Text(ex.name)))
                            .toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: MyCustomButton(
                      label: "Confirm Save",
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty || selectedIconPath == null) {
                          ScaffoldMessenger.of(sheetCtx).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a name and pick an icon.'),
                            ),
                          );
                          return;
                        }

                        final vm = context
                            .read<TemplatesViewModel>(); // grab once

                        final exerciseIds = _selectedExercises
                            .map((e) => e.id)
                            .toList();
                        final now = DateTime.now();

                        final template = WorkoutTemplateModel(
                          id: now.millisecondsSinceEpoch.toString(),
                          name: name,
                          iconPath: selectedIconPath!,
                          exerciseIds: exerciseIds,
                          createdAt: now,
                          updatedAt: now,
                        );

                        await vm.addTemplate(template);

                        if (!mounted) return;

                        // Close sheet first, then page
                        Navigator.pop(sheetCtx);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveTemplate({
    required String name,
    required String iconPath,
  }) async {
    final exerciseIds = _selectedExercises.map((e) => e.id).toList();

    final now = DateTime.now();

    final template = WorkoutTemplateModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      iconPath: iconPath,
      exerciseIds: exerciseIds,
      createdAt: now,
      updatedAt: now,
    );

    await context.read<TemplatesViewModel>().addTemplate(template);
  }
}
