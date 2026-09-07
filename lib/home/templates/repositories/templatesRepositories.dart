import 'package:workout_tracker/home/templates/models/workout_template.dart';

abstract class TemplatesRepository {
  List<WorkoutTemplateModel> getAllSorted();

  WorkoutTemplateModel? byId(String id);

  Future<void> add(WorkoutTemplateModel template);

  /// Insert [template], or replace the existing one with the same id.
  /// Used to apply server truth during a backend-authoritative pull.
  Future<void> upsert(WorkoutTemplateModel template);

  Future<void> delete(WorkoutTemplateModel template);

  Future<void> rename(WorkoutTemplateModel template, String newName);

  Future<void> changeIconPath(
    WorkoutTemplateModel template,
    String newIconPath,
  );

  Future<void> updateExercises(
    WorkoutTemplateModel template,
    List<int> newExerciseIds,
  );

  /// Combined edit (name/icon/exercise list+order) in one write, for the
  /// full template-editor screen — avoids three separate Hive writes (and
  /// three separate backend pushes) for what is, from the user's point of
  /// view, a single save. Pass only the fields that changed.
  Future<void> update(
    WorkoutTemplateModel template, {
    String? name,
    String? iconPath,
    List<int>? exerciseIds,
  });
}
