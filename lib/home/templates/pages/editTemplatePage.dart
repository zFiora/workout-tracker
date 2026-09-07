import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/reorder_support.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/common/theme/workout_icons.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';

/// One screen for everything a template edit needs — name, icon, and which
/// exercises belong to it (with reordering) — rather than separate menu
/// actions for each. A single Save commits everything together; back/cancel
/// never touches the stored template unless Save was actually pressed.
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
  late final _nameCtrl = TextEditingController(text: widget.template.name);
  late String _iconPath = widget.template.iconPath;
  late List<int> _orderedIds = List.of(widget.template.exerciseIds);
  String _search = '';

  bool get _isDirty {
    if (_nameCtrl.text.trim() != widget.template.name) return true;
    if (_iconPath != widget.template.iconPath) return true;
    if (_orderedIds.length != widget.template.exerciseIds.length) return true;
    for (var i = 0; i < _orderedIds.length; i++) {
      if (_orderedIds[i] != widget.template.exerciseIds[i]) return true;
    }
    return false;
  }

  ExerciseModel? _exerciseFor(int id) {
    for (final e in widget.allExercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          "You've made changes to this template that haven't been saved.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _save() async {
    if (_orderedIds.isEmpty) {
      Mycustomsnackbar.show(
        context,
        message: 'Select at least one exercise.',
        type: SnackbarType.warning,
      );
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      Mycustomsnackbar.show(
        context,
        message: 'Give the template a name.',
        type: SnackbarType.warning,
      );
      return;
    }

    if (!_isDirty) {
      Navigator.pop(context, false);
      return;
    }

    await context.read<TemplatesViewModel>().updateTemplate(
      widget.template,
      name: name == widget.template.name ? null : name,
      iconPath: _iconPath == widget.template.iconPath ? null : _iconPath,
      exerciseIds: _orderedIds,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
    Mycustomsnackbar.show(
      context,
      message: 'Template updated',
      type: SnackbarType.success,
    );
  }

  void _remove(int id) => setState(() => _orderedIds.remove(id));

  void _add(int id) => setState(() => _orderedIds.add(id));

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      var target = newIndex;
      if (target > oldIndex) target -= 1;
      final id = _orderedIds.removeAt(oldIndex);
      _orderedIds.insert(target, id);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final available = widget.allExercises
        .where((e) => !_orderedIds.contains(e.id))
        .where(
          (e) => _search.isEmpty ||
              e.name.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.pop(context, false);
        }
      },
      child: MyCustomeScaffoldView(
        title: 'Edit "${widget.template.name}"',
        navigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: VoltButton(
              onPressed: _save,
              icon: Icons.check_rounded,
              label: _isDirty
                  ? 'Save Changes (${_orderedIds.length} exercises)'
                  : 'No changes',
            ),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Template name',
                    prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SectionHeader(
                  title: 'Icon',
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 68,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: WorkoutIcons.pickerKeys.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final key = WorkoutIcons.pickerKeys[i];
                    // Compare by logical key so a legacy stored path still
                    // highlights its matching icon on open.
                    final selected = WorkoutIcons.keyFromStored(_iconPath) == key;
                    return GestureDetector(
                      onTap: () => setState(() => _iconPath = key),
                      child: Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: selected
                              ? cs.primary.withValues(alpha: 0.12)
                              : cs.surfaceContainerHigh,
                          border: Border.all(
                            color: selected ? cs.primary : Colors.transparent,
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: WorkoutIconImage(key),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SectionHeader(
                  title: 'In this template (${_orderedIds.length})',
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_orderedIds.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'No exercises yet — add some below.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              )
            else
              SliverReorderableList(
                itemCount: _orderedIds.length,
                onReorder: _reorder,
                proxyDecorator: liftProxyDecorator,
                itemBuilder: (context, i) {
                  final id = _orderedIds[i];
                  final ex = _exerciseFor(id);
                  return _TemplateExerciseRow(
                    key: ValueKey(id),
                    index: i,
                    name: ex?.name ?? 'Unknown exercise',
                    imagePath: ex?.workoutImage,
                    category: ex?.category.displayName,
                    onRemove: () => _remove(id),
                  );
                },
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Add exercises', padding: EdgeInsets.zero),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search exercises…',
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
              sliver: SliverList.builder(
                itemCount: available.length,
                itemBuilder: (_, i) {
                  final ex = available[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: ClipRRect(
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
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                    trailing: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(64, 32),
                      ),
                      onPressed: () => _add(ex.id),
                      child: const Text('Add'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateExerciseRow extends StatelessWidget {
  const _TemplateExerciseRow({
    required super.key,
    required this.index,
    required this.name,
    required this.imagePath,
    required this.category,
    required this.onRemove,
  });

  final int index;
  final String name;
  final String? imagePath;
  final String? category;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imagePath == null
                ? const Icon(Icons.sports_gymnastics, size: 38)
                : Image.asset(
                    imagePath!,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) =>
                        const Icon(Icons.sports_gymnastics, size: 38),
                  ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: category == null
              ? null
              : Text(category!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Remove',
                icon: Icon(Icons.close_rounded, color: cs.error, size: 20),
                onPressed: onRemove,
              ),
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
