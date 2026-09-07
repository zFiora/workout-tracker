import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/models/sex.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';

/// Single source of truth for muscle-group / template icons and how they
/// switch by the user's selected [Sex].
///
/// Icons are addressed by a stable *logical key* ("chest", "back", …). New
/// template icons are stored as keys, and every render resolves the key to
/// the concrete male / female / neutral asset for the current sex — so
/// changing sex re-themes existing data with no migration. Legacy templates
/// that stored a full emoji path still resolve correctly (the path is mapped
/// back to a key), and any unrecognised value renders unchanged.
///
/// Note: the male set has no `chest` art, so male chest falls back to the
/// neutral chest emoji. `unspecified` sex uses the neutral emoji set (the
/// app's original look) throughout.
class WorkoutIcons {
  WorkoutIcons._();

  static const chest = 'chest';
  static const back = 'back';
  static const abs = 'abs';
  static const shoulders = 'shoulders';
  static const triceps = 'triceps';
  static const biceps = 'biceps';
  static const cardio = 'cardio';
  static const legs = 'legs';
  static const forearms = 'forearms';

  /// Logical keys offered by the template-icon picker, in display order.
  static const pickerKeys = <String>[
    chest,
    abs,
    back,
    shoulders,
    triceps,
    biceps,
    cardio,
    legs,
    forearms,
  ];

  static const _dir = 'assets/workout_category';

  // Complete, gender-neutral fallback set (the app's original emoji icons).
  static const _neutral = <String, String>{
    chest: '$_dir/chest_emoji.png',
    back: '$_dir/back_emoji.png',
    abs: '$_dir/abs_emoji.png',
    shoulders: '$_dir/shoulders_emoji.png',
    triceps: '$_dir/tricep_emoji.png',
    biceps: '$_dir/bicep_emoji.png',
    cardio: '$_dir/cardio_emoji.png',
    legs: '$_dir/legs_emoji.png',
    forearms: '$_dir/muscular_forearms_emoji.png',
  };

  // Male set — no `chest` file exists, so it's intentionally absent and
  // falls through to the neutral chest emoji.
  static const _male = <String, String>{
    chest: '$_dir/male/male_chest.png',
    back: '$_dir/male/male_back.webp',
    abs: '$_dir/male/male_abs.webp',
    shoulders: '$_dir/male/male_shoulders.png',
    triceps: '$_dir/male/male_tri.png',
    biceps: '$_dir/male/male_bicep.webp',
    cardio: '$_dir/male/male_cardio.png',
    legs: '$_dir/male/male_quads.webp',
    forearms: '$_dir/male/male_forearms.webp',
  };

  static const _female = <String, String>{
    chest: '$_dir/female/female_chest.png',
    back: '$_dir/female/female_back.png',
    abs: '$_dir/female/female_abs.png',
    shoulders: '$_dir/female/female_shoulders.png',
    triceps: '$_dir/female/female_tri.png',
    biceps: '$_dir/female/female_bicep.png',
    cardio: '$_dir/female/female_cardio.png',
    legs: '$_dir/female/female_quads.png',
    forearms: '$_dir/female/female_forearms.png',
  };

  /// Concrete asset for a logical [key] and [sex], with graceful fallback to
  /// the neutral set (covers the missing male-chest and any gap).
  static String assetForKey(String key, Sex sex) {
    final table = switch (sex) {
      Sex.male => _male,
      Sex.female => _female,
      Sex.unspecified => _neutral,
    };
    return table[key] ?? _neutral[key] ?? _neutral[chest]!;
  }

  /// Maps a stored icon value — a logical key, or a legacy emoji asset path —
  /// to its logical key. Returns null for anything unrecognised.
  static String? keyFromStored(String value) {
    if (_neutral.containsKey(value)) return value; // already a key
    if (value.contains('chest_emoji')) return chest;
    if (value.contains('back_emoji')) return back;
    if (value.contains('abs_emoji')) return abs;
    if (value.contains('shoulders_emoji')) return shoulders;
    if (value.contains('tricep_emoji')) return triceps;
    if (value.contains('bicep_emoji')) return biceps;
    if (value.contains('cardio_emoji')) return cardio;
    if (value.contains('legs_emoji')) return legs;
    if (value.contains('forearms_emoji') ||
        value.contains('muscular_forearms_emoji')) {
      return forearms;
    }
    return null;
  }

  /// Resolves a stored template icon (key or legacy path) to the concrete
  /// asset for [sex]. Unknown/custom values are returned unchanged so nothing
  /// ever breaks.
  static String resolve(String stored, Sex sex) {
    final key = keyFromStored(stored);
    return key == null ? stored : assetForKey(key, sex);
  }
}

/// Logical icon key for a muscle-group category.
extension WorkoutCategoryIcon on WorkoutCategory {
  String get iconKey => switch (this) {
        WorkoutCategory.cardio => WorkoutIcons.cardio,
        WorkoutCategory.chest => WorkoutIcons.chest,
        WorkoutCategory.back => WorkoutIcons.back,
        WorkoutCategory.bicepes => WorkoutIcons.biceps,
        WorkoutCategory.triceps => WorkoutIcons.triceps,
        WorkoutCategory.shoulders => WorkoutIcons.shoulders,
        WorkoutCategory.legs => WorkoutIcons.legs,
        WorkoutCategory.abs => WorkoutIcons.abs,
        WorkoutCategory.forearms => WorkoutIcons.forearms,
      };
}

/// Renders a muscle/template icon, resolving it against the current user's
/// sex and rebuilding automatically when the sex changes. Pass either a
/// stored template icon (key or legacy path) or a category's [iconKey].
class WorkoutIconImage extends StatelessWidget {
  const WorkoutIconImage(
    this.stored, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.fallback,
  });

  final String stored;
  final double? width;
  final double? height;
  final BoxFit? fit;

  /// Shown if the resolved asset fails to load. Defaults to a neutral
  /// dumbbell glyph.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final sex = context.select<AppManager, Sex>((m) => m.sex);
    final path = WorkoutIcons.resolve(stored, sex);
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          fallback ??
          Icon(
            Icons.fitness_center_rounded,
            size: (width ?? height ?? 24) * 0.9,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
