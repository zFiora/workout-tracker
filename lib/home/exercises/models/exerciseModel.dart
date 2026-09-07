// ignore_for_file: file_names

import 'package:workout_tracker/home/exercises/models/categoryModel.dart';

/// A single exercise — either a built-in catalog entry or a user-created
/// custom one ([isCustom]). Custom exercises get reserved high integer ids so
/// they never collide with the built-in 1..N range and everything that keys
/// on `int` exerciseId (templates, history, sessions) keeps working unchanged.
class ExerciseModel {
  final int id;
  final String name;
  final WorkoutCategory category;

  /// Asset path (`assets/...`) for built-ins, an absolute file path for a
  /// user-picked custom photo, or `''` for none. Render via
  /// [exerciseImageProvider] which distinguishes the two.
  final String workoutImage;

  // ── Optional richer info (populated for built-ins where sensible, and
  //    editable for custom exercises) ──────────────────────────────────────
  final String? equipment;
  final List<String> secondaryMuscles;
  final String? instructions;
  final List<String> tips;
  final List<String> commonMistakes;
  final String? difficulty; // Beginner / Intermediate / Advanced

  final bool isCustom;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.category,
    required this.workoutImage,
    this.equipment,
    this.secondaryMuscles = const [],
    this.instructions,
    this.tips = const [],
    this.commonMistakes = const [],
    this.difficulty,
    this.isCustom = false,
  });

  /// Primary muscle group, in display form (derived from [category]).
  String get primaryMuscle => category.displayName;

  /// Best-effort equipment: the explicit [equipment] if set, otherwise
  /// inferred from the name for built-ins (so the equipment filter and the
  /// detail page work without hand-annotating all 64 entries).
  String get resolvedEquipment => equipment ?? _inferEquipment(name);

  ExerciseModel copyWith({
    String? name,
    WorkoutCategory? category,
    String? workoutImage,
    String? equipment,
    List<String>? secondaryMuscles,
    String? instructions,
    List<String>? tips,
    List<String>? commonMistakes,
    String? difficulty,
  }) {
    return ExerciseModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      workoutImage: workoutImage ?? this.workoutImage,
      equipment: equipment ?? this.equipment,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      instructions: instructions ?? this.instructions,
      tips: tips ?? this.tips,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      difficulty: difficulty ?? this.difficulty,
      isCustom: isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'workoutImage': workoutImage,
        'equipment': equipment,
        'secondaryMuscles': secondaryMuscles,
        'instructions': instructions,
        'tips': tips,
        'commonMistakes': commonMistakes,
        'difficulty': difficulty,
        'isCustom': isCustom,
      };

  factory ExerciseModel.fromJson(Map<String, dynamic> j) => ExerciseModel(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        category: WorkoutCategory.values.firstWhere(
          (c) => c.name == j['category'],
          orElse: () => WorkoutCategory.chest,
        ),
        workoutImage: j['workoutImage'] as String? ?? '',
        equipment: j['equipment'] as String?,
        secondaryMuscles:
            (j['secondaryMuscles'] as List?)?.cast<String>() ?? const [],
        instructions: j['instructions'] as String?,
        tips: (j['tips'] as List?)?.cast<String>() ?? const [],
        commonMistakes:
            (j['commonMistakes'] as List?)?.cast<String>() ?? const [],
        difficulty: j['difficulty'] as String?,
        isCustom: j['isCustom'] as bool? ?? true,
      );
}

/// Common equipment options offered when creating a custom exercise (and the
/// vocabulary the name-inference below maps onto).
const kEquipmentOptions = <String>[
  'Barbell',
  'Dumbbell',
  'Machine',
  'Cable',
  'Smith Machine',
  'Bodyweight',
  'Kettlebell',
  'Bands',
  'Other',
];

String _inferEquipment(String name) {
  final n = name.toLowerCase();
  if (n.contains('smith')) return 'Smith Machine';
  if (n.contains('barbell') || n.contains('bar ') || n.contains('t bar')) {
    return 'Barbell';
  }
  if (n.contains('dumbble') || n.contains('dumbbell') || n.contains('dummbble')) {
    return 'Dumbbell';
  }
  if (n.contains('cable') || n.contains('cabel')) return 'Cable';
  if (n.contains('machine')) return 'Machine';
  if (n.contains('kettlebell')) return 'Kettlebell';
  if (n.contains('band')) return 'Bands';
  if (n.contains('pull up') ||
      n.contains('pull-up') ||
      n.contains('dip') ||
      n.contains('raise') ||
      n.contains('crunch') ||
      n.contains('plank')) {
    return 'Bodyweight';
  }
  return 'Other';
}
