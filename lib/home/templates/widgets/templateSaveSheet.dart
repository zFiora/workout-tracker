import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/templates/constants/templateIcons.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';

class TemplateSaveSheet extends StatefulWidget {
  const TemplateSaveSheet({super.key, required this.selectedExercises});

  final Set<ExerciseModel> selectedExercises;

  @override
  State<TemplateSaveSheet> createState() => _TemplateSaveSheetState();
}

class _TemplateSaveSheetState extends State<TemplateSaveSheet> {
  final _nameController = TextEditingController();
  String? _selectedIconPath;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext sheetCtx) async {
    final name = _nameController.text.trim();
    final icon = _selectedIconPath;

    if (name.isEmpty || icon == null) {
      ScaffoldMessenger.of(sheetCtx).showSnackBar(
        const SnackBar(content: Text('Enter a name and pick an icon.')),
      );
      return;
    }

    final vm = context.read<TemplatesViewModel>();
    final now = DateTime.now();

    final template = WorkoutTemplateModel(
      id: const Uuid().v4(),
      name: name,
      iconPath: icon,
      exerciseIds: widget.selectedExercises.map((e) => e.id).toList(),
      createdAt: now,
      updatedAt: now,
    );

    await vm.addTemplate(template);

    if (!mounted) return;
    Navigator.pop(sheetCtx, true); // close sheet and signal success
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: "Template Name",
              prefixIcon: Icon(Icons.text_fields),
            ),
          ),
          const SizedBox(height: 12),

          Text("Pick an Icon", style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),

          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: TemplateIcons.icons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final path = TemplateIcons.icons[i];
                final selected = path == _selectedIconPath;
                final cs = Theme.of(context).colorScheme;

                return GestureDetector(
                  onTap: () => setState(() => _selectedIconPath = path),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? cs.primary : cs.outlineVariant,
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
            "Selected Exercises (${widget.selectedExercises.length})",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.selectedExercises
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
              onPressed: () => _save(context),
            ),
          ),
        ],
      ),
    );
  }
}
