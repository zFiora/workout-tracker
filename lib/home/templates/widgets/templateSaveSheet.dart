import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_tracker/common/theme/workout_icons.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';

class TemplateSaveSheet extends StatefulWidget {
  const TemplateSaveSheet({super.key, required this.selectedExercises});

  final Set<ExerciseModel> selectedExercises;

  @override
  State<TemplateSaveSheet> createState() => _TemplateSaveSheetState();
}

class _TemplateSaveSheetState extends State<TemplateSaveSheet> {
  final _nameController = TextEditingController();
  // Stores the logical icon *key* (e.g. "chest"); resolved to a gendered
  // asset at render time.
  String? _selectedIconKey;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext sheetCtx) async {
    final name = _nameController.text.trim();
    final icon = _selectedIconKey;

    if (name.isEmpty || icon == null) {
      Mycustomsnackbar.show(
        sheetCtx,
        message: 'Enter a name and pick an icon.',
        type: SnackbarType.warning,
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
          Center(
            child: SheetHeader(
              title: 'Review & Save',
              onClose: () => Navigator.pop(context, false),
            ),
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

          const SectionHeader(
            title: 'Pick an icon',
            padding: EdgeInsets.only(bottom: 8),
          ),

          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: WorkoutIcons.pickerKeys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final key = WorkoutIcons.pickerKeys[i];
                final selected = key == _selectedIconKey;
                final cs = Theme.of(context).colorScheme;

                return GestureDetector(
                  onTap: () => setState(() => _selectedIconKey = key),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: selected
                          ? cs.primary.withValues(alpha: 0.12)
                          : cs.surfaceContainerHigh,
                      border: Border.all(
                        color: selected ? cs.primary : Colors.transparent,
                        width: selected ? 1.6 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: WorkoutIconImage(key),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          SectionHeader(
            title: 'Selected exercises (${widget.selectedExercises.length})',
            padding: const EdgeInsets.only(bottom: 8),
          ),

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

          VoltButton(
            label: 'Confirm Save',
            icon: Icons.check_rounded,
            onPressed: () => _save(context),
          ),
        ],
      ),
    );
  }
}
