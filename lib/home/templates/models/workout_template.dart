import 'package:hive/hive.dart';

part 'workout_template.g.dart';

@HiveType(typeId: 101)
class WorkoutTemplateModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String iconPath;

  @HiveField(3)
  final List<int> exerciseIds;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  const WorkoutTemplateModel({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.exerciseIds,
    required this.createdAt,
    required this.updatedAt,
  });

  // ---------- helpers (future-proof) ----------

  WorkoutTemplateModel copyWith({
    String? name,
    String? iconPath,
    List<int>? exerciseIds,
    DateTime? updatedAt,
  }) {
    return WorkoutTemplateModel(
      id: id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ---------- JSON (online ready) ----------

  factory WorkoutTemplateModel.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconPath: json['iconPath'] as String,
      exerciseIds: List<int>.from(json['exerciseIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconPath': iconPath,
        'exerciseIds': exerciseIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
