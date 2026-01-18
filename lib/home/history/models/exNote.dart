import 'package:hive/hive.dart';
part 'exNote.g.dart';

@HiveType(typeId: 77) // make sure 77 is not used elsewhere
class ExerciseNote extends HiveObject {
  @HiveField(0)
  final int exerciseId;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final String text;

  ExerciseNote({
    required this.exerciseId,
    required this.createdAt,
    required this.text,
  });
}
