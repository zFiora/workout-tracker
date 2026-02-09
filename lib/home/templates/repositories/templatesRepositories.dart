import 'package:workout_tracker/home/templates/models/workout_template.dart';

abstract class TemplatesRepository {
  List<WorkoutTemplateModel> getAllSorted();

  WorkoutTemplateModel? byId(String id);

  Future<void> add(WorkoutTemplateModel template);

  Future<void> delete(WorkoutTemplateModel template);

  Future<void> rename(WorkoutTemplateModel template, String newName);

  Future<void> changeIconPath(
    WorkoutTemplateModel template,
    String newIconPath,
  );
}
