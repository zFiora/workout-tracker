import 'package:hive/hive.dart';

part 'workoutTemplateModel.g.dart';

@HiveType(typeId: 1) 
class WorkoutTemplateModel extends HiveObject {
  @HiveField(0)
  String id; 

  @HiveField(1)
  String name;

  @HiveField(2)
  String iconPath; 

  @HiveField(3)
  List<int> exerciseIds; 

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  WorkoutTemplateModel({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.exerciseIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
