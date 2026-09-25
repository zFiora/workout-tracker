import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Exercise → muscle mapping.
//
// ALL built-in mappings live in [kBuiltInExerciseMuscles] below, keyed by the
// catalog id in `exerciesesList.dart`. Edit this table to change what the
// post-workout muscle summary highlights; nothing else stores muscle data.
//
// Conventions (standard exercise anatomy, simplified to the 16 [Muscle]
// regions):
//   • primary   — the muscle(s) the exercise is chosen to train.
//   • secondary — muscles meaningfully involved as synergists/stabilisers.
//   • An empty secondary set is explicit: isolation movements have none.
//   • No muscle is ever both primary and secondary (enforced by a test).
// ─────────────────────────────────────────────────────────────────────────────

const _pressChest = MuscleTargets(
  primary: {Muscle.chest},
  secondary: {Muscle.frontDelts, Muscle.triceps},
);
const _flyChest = MuscleTargets(
  primary: {Muscle.chest},
  secondary: {Muscle.frontDelts},
);
const _verticalPull = MuscleTargets(
  primary: {Muscle.lats},
  secondary: {Muscle.biceps, Muscle.traps, Muscle.rearDelts},
);
const _supportedRow = MuscleTargets(
  primary: {Muscle.lats, Muscle.traps},
  secondary: {Muscle.rearDelts, Muscle.biceps},
);
const _freeRow = MuscleTargets(
  primary: {Muscle.lats, Muscle.traps},
  secondary: {Muscle.rearDelts, Muscle.biceps, Muscle.lowerBack},
);
const _dip = MuscleTargets(
  primary: {Muscle.triceps},
  secondary: {Muscle.chest, Muscle.frontDelts},
);
const _tricepIsolation = MuscleTargets(primary: {Muscle.triceps}, secondary: {});
const _curl = MuscleTargets(primary: {Muscle.biceps}, secondary: {Muscle.forearms});
const _hammerCurl = MuscleTargets(
  primary: {Muscle.biceps, Muscle.forearms},
  secondary: {},
);
const _lateralRaise = MuscleTargets(
  primary: {Muscle.sideDelts},
  secondary: {Muscle.frontDelts, Muscle.traps},
);
const _overheadPress = MuscleTargets(
  primary: {Muscle.frontDelts},
  secondary: {Muscle.sideDelts, Muscle.triceps},
);
const _shrug = MuscleTargets(primary: {Muscle.traps}, secondary: {Muscle.forearms});
const _crunch = MuscleTargets(primary: {Muscle.abs}, secondary: {Muscle.obliques});
const _legCurl = MuscleTargets(primary: {Muscle.hamstrings}, secondary: {Muscle.calves});
const _calfRaise = MuscleTargets(primary: {Muscle.calves}, secondary: {});

/// Every built-in exercise id → its muscles. Names are the catalog names.
const Map<int, MuscleTargets> kBuiltInExerciseMuscles = {
  // ── Chest ──
  1: _flyChest, // Chest Fly (Machine)
  2: _pressChest, // Inclined Dumbble press
  3: _pressChest, // Bench Press (Barbell)
  4: _pressChest, // Flat Smith Press
  5: _pressChest, // Inclined Smith Press
  50: _pressChest, // Machine Chest Press
  51: _flyChest, // Cable Crossover
  105: _flyChest, // Cable Crossover
  106: _pressChest, // Incline Bench Press
  107: _pressChest, // Incline Chest Press ( Machine )

  // ── Back ──
  6: _verticalPull, // Lat Pull Down Cabel
  7: _verticalPull, // Lat Pull Down
  8: _supportedRow, // Cable Back Row
  9: _supportedRow, // Machine Back Row
  10: _freeRow, // T Bar Row
  11: _verticalPull, // Pull Up
  12: _verticalPull, // Assissted Pull Up
  13: MuscleTargets( // Lower Back Extention
    primary: {Muscle.lowerBack},
    secondary: {Muscle.glutes, Muscle.hamstrings},
  ),
  49: _verticalPull, // Close Grip Lat Pulldown
  101: _supportedRow, // Dumbbell Back Row (bench-supported)
  102: _supportedRow, // Linear Back Row Machine
  103: _freeRow, // Barbell Back Row

  // ── Triceps ──
  14: _dip, // Assissted Triceps Dip
  15: _dip, // Triceps Machine Dip
  16: _tricepIsolation, // Single Arm Tricep Push Down
  17: _tricepIsolation, // Triceps Extention
  18: _tricepIsolation, // Triceps Push Down
  110: _tricepIsolation, // Incline triceps pushdown (formerly a duplicate 108)

  // ── Biceps ──
  19: _curl, // Biceps Barbell Curl
  20: _curl, // Bayesian Curl
  21: _hammerCurl, // Cable Hammer Curl
  22: _curl, // Preacher Curl
  23: _curl, // Seated Incline Curl
  104: _hammerCurl, // Dumbbell Hammer Curls

  // ── Shoulders ──
  24: MuscleTargets( // Face Pull
    primary: {Muscle.rearDelts},
    secondary: {Muscle.traps},
  ),
  25: _lateralRaise, // Lateral Raise (Cable)
  26: _lateralRaise, // Lateral Raise (Dumbbell)
  27: _lateralRaise, // Lateral Raise (Machine)
  28: MuscleTargets( // Reverse Fly (Machine)
    primary: {Muscle.rearDelts},
    secondary: {Muscle.traps},
  ),
  29: _overheadPress, // Shoulder Press (Barbell)
  30: _overheadPress, // Shoulder Press (Dumbbell)
  31: _overheadPress, // Shoulder Press (Machine)
  47: _shrug, // Dumbbell Shrugs
  48: _shrug, // Machine Shrugs

  // ── Abs ──
  32: MuscleTargets( // Abs Twist
    primary: {Muscle.obliques},
    secondary: {Muscle.abs},
  ),
  33: _crunch, // Decline Set-up
  34: _crunch, // Leg Raises
  35: _crunch, // Machine Abs Crunch
  100: _crunch, // Dragon flag

  // ── Legs ──
  36: MuscleTargets( // Bulgarian Split Squat
    primary: {Muscle.quads, Muscle.glutes},
    secondary: {Muscle.hamstrings},
  ),
  37: MuscleTargets( // Squat
    primary: {Muscle.quads, Muscle.glutes},
    secondary: {Muscle.hamstrings, Muscle.lowerBack},
  ),
  38: MuscleTargets( // Hack Squat
    primary: {Muscle.quads},
    secondary: {Muscle.glutes, Muscle.hamstrings},
  ),
  39: MuscleTargets( // Leg Press
    primary: {Muscle.quads},
    secondary: {Muscle.glutes, Muscle.hamstrings},
  ),
  40: MuscleTargets(primary: {Muscle.quads}, secondary: {}), // Leg Extension
  41: _legCurl, // Seated Leg Curl
  42: _legCurl, // Laying Leg Curl
  43: MuscleTargets( // Romanian Deadlift (RDL)
    primary: {Muscle.hamstrings, Muscle.glutes},
    secondary: {Muscle.lowerBack, Muscle.forearms},
  ),
  44: MuscleTargets( // Deadlift
    primary: {Muscle.hamstrings, Muscle.glutes, Muscle.lowerBack},
    secondary: {Muscle.quads, Muscle.traps, Muscle.forearms},
  ),
  45: _calfRaise, // Seated Calf Press
  46: _calfRaise, // Calf Raises
  52: MuscleTargets( // Hip Thrust
    primary: {Muscle.glutes},
    secondary: {Muscle.hamstrings, Muscle.quads},
  ),
  53: _calfRaise, // Seated Calf Raise
  108: MuscleTargets(primary: {Muscle.glutes}, secondary: {}), // Hip Abduction
  // Adductors aren't a separate region; the inner thigh is drawn as part of
  // the quads region, so adduction highlights it there.
  109: MuscleTargets(primary: {Muscle.quads}, secondary: {}), // Hip Adduction
};

// ── Custom exercises ─────────────────────────────────────────────────────────

/// Broad-category fallback for custom exercises: the whole group is primary.
const Map<WorkoutCategory, Set<Muscle>> kCategoryFallbackMuscles = {
  WorkoutCategory.chest: {Muscle.chest},
  WorkoutCategory.back: {Muscle.lats, Muscle.traps, Muscle.lowerBack},
  WorkoutCategory.shoulders: {Muscle.frontDelts, Muscle.sideDelts, Muscle.rearDelts},
  WorkoutCategory.bicepes: {Muscle.biceps},
  WorkoutCategory.triceps: {Muscle.triceps},
  WorkoutCategory.forearms: {Muscle.forearms},
  WorkoutCategory.abs: {Muscle.abs, Muscle.obliques},
  WorkoutCategory.legs: {Muscle.quads, Muscle.hamstrings, Muscle.glutes, Muscle.calves},
  WorkoutCategory.cardio: {},
};

/// Recognised spellings for the free-text secondary muscles users type on
/// custom exercises (matched after [_normalize]). Group words map to the same
/// sets as [kCategoryFallbackMuscles]. Anything else is ignored.
const Map<String, Set<Muscle>> _aliases = {
  'chest': {Muscle.chest},
  'pec': {Muscle.chest},
  'pecs': {Muscle.chest},
  'pectorals': {Muscle.chest},
  'front delt': {Muscle.frontDelts},
  'front delts': {Muscle.frontDelts},
  'front deltoid': {Muscle.frontDelts},
  'front deltoids': {Muscle.frontDelts},
  'front shoulder': {Muscle.frontDelts},
  'front shoulders': {Muscle.frontDelts},
  'anterior deltoid': {Muscle.frontDelts},
  'side delt': {Muscle.sideDelts},
  'side delts': {Muscle.sideDelts},
  'side deltoid': {Muscle.sideDelts},
  'side deltoids': {Muscle.sideDelts},
  'lateral delt': {Muscle.sideDelts},
  'lateral delts': {Muscle.sideDelts},
  'lateral deltoid': {Muscle.sideDelts},
  'middle delts': {Muscle.sideDelts},
  'rear delt': {Muscle.rearDelts},
  'rear delts': {Muscle.rearDelts},
  'rear deltoid': {Muscle.rearDelts},
  'rear deltoids': {Muscle.rearDelts},
  'posterior deltoid': {Muscle.rearDelts},
  'shoulder': {Muscle.frontDelts, Muscle.sideDelts, Muscle.rearDelts},
  'shoulders': {Muscle.frontDelts, Muscle.sideDelts, Muscle.rearDelts},
  'delts': {Muscle.frontDelts, Muscle.sideDelts, Muscle.rearDelts},
  'deltoids': {Muscle.frontDelts, Muscle.sideDelts, Muscle.rearDelts},
  'bicep': {Muscle.biceps},
  'biceps': {Muscle.biceps},
  'tricep': {Muscle.triceps},
  'triceps': {Muscle.triceps},
  'forearm': {Muscle.forearms},
  'forearms': {Muscle.forearms},
  'grip': {Muscle.forearms},
  'brachioradialis': {Muscle.forearms},
  'abs': {Muscle.abs},
  'abdominals': {Muscle.abs},
  'rectus abdominis': {Muscle.abs},
  'core': {Muscle.abs, Muscle.obliques},
  'oblique': {Muscle.obliques},
  'obliques': {Muscle.obliques},
  'lat': {Muscle.lats},
  'lats': {Muscle.lats},
  'latissimus dorsi': {Muscle.lats},
  'trap': {Muscle.traps},
  'traps': {Muscle.traps},
  'trapezius': {Muscle.traps},
  'upper back': {Muscle.traps},
  'rhomboids': {Muscle.traps},
  'back': {Muscle.lats, Muscle.traps, Muscle.lowerBack},
  'lower back': {Muscle.lowerBack},
  'lowerback': {Muscle.lowerBack},
  'erectors': {Muscle.lowerBack},
  'erector spinae': {Muscle.lowerBack},
  'glute': {Muscle.glutes},
  'glutes': {Muscle.glutes},
  'gluteus': {Muscle.glutes},
  'quad': {Muscle.quads},
  'quads': {Muscle.quads},
  'quadriceps': {Muscle.quads},
  'hamstring': {Muscle.hamstrings},
  'hamstrings': {Muscle.hamstrings},
  'hams': {Muscle.hamstrings},
  'calf': {Muscle.calves},
  'calves': {Muscle.calves},
  'gastrocnemius': {Muscle.calves},
  'soleus': {Muscle.calves},
  'legs': {Muscle.quads, Muscle.hamstrings, Muscle.glutes, Muscle.calves},
};

String _normalize(String raw) => raw
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z ]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Muscles for a free-text muscle name, or an empty set if unrecognised.
Set<Muscle> musclesForName(String raw) => _aliases[_normalize(raw)] ?? const {};

/// Targets for a user-created exercise: its category as primary, plus any
/// recognised typed secondary muscles that aren't already primary.
MuscleTargets muscleTargetsForCustom(ExerciseModel exercise) {
  final primary = {...?kCategoryFallbackMuscles[exercise.category]};
  final secondary = <Muscle>{
    for (final name in exercise.secondaryMuscles) ...musclesForName(name),
  }..removeAll(primary);
  return MuscleTargets(primary: primary, secondary: secondary);
}
