import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/exercises/custom_exercise_image_store.dart';
import 'package:workout_tracker/home/exercises/custom_exercises_repository.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/widgets/exercise_image.dart';

/// Create or edit a custom exercise. Returns the saved [ExerciseModel] (or
/// null if cancelled). Pass [existing] to edit.
class CustomExerciseEditorPage extends StatefulWidget {
  const CustomExerciseEditorPage({super.key, this.existing});

  final ExerciseModel? existing;

  @override
  State<CustomExerciseEditorPage> createState() =>
      _CustomExerciseEditorPageState();
}

class _CustomExerciseEditorPageState extends State<CustomExerciseEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  late final _secondaryCtrl = TextEditingController(
      text: (widget.existing?.secondaryMuscles ?? const []).join(', '));
  late final _instructionsCtrl =
      TextEditingController(text: widget.existing?.instructions ?? '');
  late final _tipsCtrl = TextEditingController(
      text: (widget.existing?.tips ?? const []).join('\n'));
  late final _mistakesCtrl = TextEditingController(
      text: (widget.existing?.commonMistakes ?? const []).join('\n'));

  late WorkoutCategory _category =
      widget.existing?.category ?? WorkoutCategory.chest;
  late String _equipment =
      widget.existing?.equipment ?? kEquipmentOptions.first;
  late String? _difficulty = widget.existing?.difficulty;
  late String _imagePath = widget.existing?.workoutImage ?? '';
  bool _saving = false;

  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _secondaryCtrl.dispose();
    _instructionsCtrl.dispose();
    _tipsCtrl.dispose();
    _mistakesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            if (_imagePath.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: Theme.of(ctx).colorScheme.error),
                title: const Text('Remove photo'),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return; // dismissed

    if (action == 'remove') {
      setState(() => _imagePath = '');
      return;
    }

    try {
      final picked = await ImagePicker().pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;
      final permanent = await ExerciseImageStore.persist(picked.path);
      setState(() => _imagePath = permanent);
    } catch (_) {
      if (mounted) {
        Mycustomsnackbar.show(context,
            message: "Couldn't add that photo.", type: SnackbarType.warning);
      }
    }
  }

  List<String> _lines(String raw) => raw
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  List<String> _csv(String raw) => raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = CustomExercisesRepository.I;
    final draft = ExerciseModel(
      id: widget.existing?.id ?? 0, // repo assigns a reserved id on create
      name: _nameCtrl.text.trim(),
      category: _category,
      workoutImage: _imagePath,
      equipment: _equipment,
      secondaryMuscles: _csv(_secondaryCtrl.text),
      instructions: _instructionsCtrl.text.trim().isEmpty
          ? null
          : _instructionsCtrl.text.trim(),
      tips: _lines(_tipsCtrl.text),
      commonMistakes: _lines(_mistakesCtrl.text),
      difficulty: _difficulty,
      isCustom: true,
    );

    final ExerciseModel saved;
    if (widget.existing == null) {
      saved = await repo.create(draft);
    } else {
      await repo.update(draft);
      saved = draft;
    }

    if (!mounted) return;
    Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final editing = widget.existing != null;

    return MyCustomeScaffoldView(
      title: editing ? 'Edit Exercise' : 'New Exercise',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Photo
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imagePath.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: cs.onSurfaceVariant),
                            const SizedBox(height: 6),
                            Text('Add photo',
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurfaceVariant)),
                          ],
                        )
                      : ExerciseImage(path: _imagePath, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<WorkoutCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Primary muscle *',
                prefixIcon: Icon(Icons.accessibility_new_rounded),
              ),
              items: [
                for (final c in WorkoutCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.displayName)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _equipment,
              decoration: const InputDecoration(
                labelText: 'Equipment',
                prefixIcon: Icon(Icons.fitness_center_rounded),
              ),
              items: [
                for (final e in kEquipmentOptions)
                  DropdownMenuItem(value: e, child: Text(e)),
              ],
              onChanged: (v) => setState(() => _equipment = v ?? _equipment),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              value: _difficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                prefixIcon: Icon(Icons.speed_rounded),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                for (final d in _difficulties)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (v) => setState(() => _difficulty = v),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _secondaryCtrl,
              decoration: const InputDecoration(
                labelText: 'Secondary muscles (comma separated)',
                prefixIcon: Icon(Icons.add_circle_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _instructionsCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'How to perform',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _tipsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Tips (one per line)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _mistakesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Common mistakes (one per line)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            VoltButton(
              label: editing ? 'Save Changes' : 'Create Exercise',
              icon: Icons.check_rounded,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
