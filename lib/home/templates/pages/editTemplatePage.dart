import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';

class EditTemplatePage extends StatefulWidget {
  const EditTemplatePage({
    super.key,
    required this.template,
    required this.allExercises,
  });

  final WorkoutTemplateModel template;
  final List<ExerciseModel> allExercises;

  @override
  State<EditTemplatePage> createState() => _EditTemplatePageState();
}

class _EditTemplatePageState extends State<EditTemplatePage> {
  late final Set<int> _selectedIds;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.of(widget.template.exerciseIds);
  }

  Future<void> _save() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one exercise.')),
      );
      return;
    }

    // Preserve ordering: existing order first, then new additions at the end
    final existingOrdered = widget.template.exerciseIds
        .where((id) => _selectedIds.contains(id))
        .toList();
    final added = _selectedIds
        .where((id) => !widget.template.exerciseIds.contains(id))
        .toList();
    final newIds = [...existingOrdered, ...added];

    await context
        .read<TemplatesViewModel>()
        .updateExercises(widget.template, newIds);

    if (!mounted) return;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final filtered = _search.isEmpty
        ? widget.allExercises
        : widget.allExercises
            .where(
              (e) => e.name.toLowerCase().contains(_search.toLowerCase()),
            )
            .toList();

    return MyCustomeScaffoldView(
      title: 'Edit Template',
      body: Column(
        children: [
          // Search + selected chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search exercises…',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: _selectedIds.isEmpty
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(
                            label: Text(
                              'No exercises selected',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          children: _selectedIds.map((id) {
                            final ex = widget.allExercises.firstWhere(
                              (e) => e.id == id,
                              orElse: () => widget.allExercises.first,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(
                                  ex.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () =>
                                    setState(() => _selectedIds.remove(id)),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 100),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final ex = filtered[i];
                final selected = _selectedIds.contains(ex.id);

                return CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  secondary: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      ex.workoutImage,
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) =>
                          const Icon(Icons.sports_gymnastics, size: 38),
                    ),
                  ),
                  title: Text(
                    ex.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    ex.category.displayName,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  value: selected,
                  activeColor: cs.primary,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedIds.add(ex.id);
                      } else {
                        _selectedIds.remove(ex.id);
                      }
                    });
                  },
                );
              },
            ),
          ),

          // Save button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: VoltButton(
                onPressed: _save,
                icon: Icons.check_rounded,
                label: 'Save Changes (${_selectedIds.length} exercises)',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
