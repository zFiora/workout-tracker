// ignore_for_file: file_names

enum WorkoutCategory {
  cardio,
  chest,
  back,
  bicepes,
  triceps,
  shoulders,
  legs,
  abs,
  forearms,
}

extension WorkoutCategoryExtension on WorkoutCategory {
  String get displayName {
    switch (this) {
      case WorkoutCategory.cardio:
        return 'Cardio';
      case WorkoutCategory.chest:
        return 'Chest';
      case WorkoutCategory.back:
        return 'Back';
      case WorkoutCategory.bicepes:
        return 'Biceps';
      case WorkoutCategory.triceps:
        return 'Triceps';
      case WorkoutCategory.shoulders:
        return 'Shoulders';
      case WorkoutCategory.legs:
        return 'Legs';
      case WorkoutCategory.abs:
        return 'Abs';
      case WorkoutCategory.forearms:
        return 'Forearms';
    }
  }

  /// Return the path to the proper image asset
  String get icon {
    switch (this) {
      case WorkoutCategory.cardio:
        return 'assets/workout_category/cardio_emoji.png';
      case WorkoutCategory.chest:
        return 'assets/workout_category/chest_emoji.png';
      case WorkoutCategory.back:
        return 'assets/workout_category/back_emoji.png';
      case WorkoutCategory.bicepes:
        return 'assets/workout_category/bicep_emoji.png';
      case WorkoutCategory.triceps:
        return 'assets/workout_category/tricep_emoji.png';
      case WorkoutCategory.shoulders:
        return 'assets/workout_category/shoulders_emoji.png';
      case WorkoutCategory.legs:
        return 'assets/workout_category/legs_emoji.png';
      case WorkoutCategory.abs:
        return 'assets/workout_category/abs_emoji.png';
      case WorkoutCategory.forearms:
        return 'assets/workout_category/muscular_forearms_emoji.png';
    }
  }
}
