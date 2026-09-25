/// The muscle regions the app can highlight on the body map. Deliberately
/// coarser than full anatomy — one value per region drawn by
/// `MuscleMapView` — so every value here is visible on the front or back view.
enum Muscle {
  chest,
  frontDelts,
  sideDelts,
  rearDelts,
  biceps,
  triceps,
  forearms,
  abs,
  obliques,
  lats,
  traps,
  lowerBack,
  glutes,
  quads,
  hamstrings,
  calves,
}

extension MuscleX on Muscle {
  String get displayName => switch (this) {
        Muscle.chest => 'Chest',
        Muscle.frontDelts => 'Front Delts',
        Muscle.sideDelts => 'Side Delts',
        Muscle.rearDelts => 'Rear Delts',
        Muscle.biceps => 'Biceps',
        Muscle.triceps => 'Triceps',
        Muscle.forearms => 'Forearms',
        Muscle.abs => 'Abs',
        Muscle.obliques => 'Obliques',
        Muscle.lats => 'Lats',
        Muscle.traps => 'Traps / Upper Back',
        Muscle.lowerBack => 'Lower Back',
        Muscle.glutes => 'Glutes',
        Muscle.quads => 'Quads',
        Muscle.hamstrings => 'Hamstrings',
        Muscle.calves => 'Calves',
      };
}

/// Primary and secondary muscles for one exercise. The constructor does not
/// enforce disjointness; `muscleTargetsFor*` and the calculation both treat
/// primary as winning over secondary.
class MuscleTargets {
  const MuscleTargets({required this.primary, required this.secondary});

  final Set<Muscle> primary;
  final Set<Muscle> secondary;

  static const none = MuscleTargets(primary: {}, secondary: {});

  bool get isEmpty => primary.isEmpty && secondary.isEmpty;
}
