// ignore_for_file: file_names

import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:flutter/material.dart';

class ExercisesViewModel extends ChangeNotifier {
  final List<ExerciseModel> _exercises = [
    ExerciseModel(
      id: 1,
      name: 'Chest Fly (Machine)',
      category: WorkoutCategory.chest,
      workoutImage: 'assets/workouts/chest/chest_fly_(machine).png',
    ),
    ExerciseModel(
      id: 2,
      name: 'Inclined Dumbble press',
      category: WorkoutCategory.chest,
      workoutImage: 'assets/workouts/chest/incline_dumbbell_press.png',
    ),
    ExerciseModel(
      id: 3,
      name: 'Bench Press (Barbell)',
      category: WorkoutCategory.chest,
      workoutImage: 'assets/workouts/chest/bench_press_barbell.png',
    ),
    ExerciseModel(
      id: 4,
      name: 'Flat Smith Press',
      category: WorkoutCategory.chest,
      workoutImage: 'assets/workouts/chest/flat_smith_press.png',
    ),

    ExerciseModel(
      id: 5,
      name: 'Inclined Smith Press',
      category: WorkoutCategory.chest,
      workoutImage: 'assets/workouts/chest/incline_smith_press.png',
    ),

    ExerciseModel(
      id: 6,
      name: 'Lat Pull Down Cabel',
      category: WorkoutCategory.back,
      workoutImage: 'assets/workouts/back/lat_pulldown.png',
    ),
    ExerciseModel(
      id: 7,
      name: 'Lat Pull Down',
      category: WorkoutCategory.back,
      workoutImage: 'assets/workouts/back/panta_lat_pulldown.png',
    ),
    ExerciseModel(
      id: 8,
      name: 'Cable Back Row',
      category: WorkoutCategory.back,
      workoutImage: 'assets/workouts/back/cabel_back_row.png',
    ),
    ExerciseModel(
      id: 9,
      name: 'Machine Back Row',
      category: WorkoutCategory.back,
      workoutImage: 'assets/workouts/back/machine_back_row.png',
    ),
    ExerciseModel(
      id: 10,
      name: 'T Bar Row',
      category: WorkoutCategory.back,
      workoutImage: 'assets/workouts/back/tbar.png',
    ),
    ExerciseModel(
      id: 11,
      name: 'Pull Up',
      category: WorkoutCategory.back,
      workoutImage: 'assets/workouts/back/pull_up.png',
    ),
    ExerciseModel(
      id: 12,
      name: 'Assissted Pull Up',
      category: WorkoutCategory.back,
      workoutImage: 'assets/workouts/back/assisted_pullup.png',
    ),
    ExerciseModel(
      id: 13,
      name: 'Lower Back Extention',
      category: WorkoutCategory.back,
      workoutImage: 'assets/workouts/back/lower_back_exten.png',
    ),

    ExerciseModel(
      id: 14,
      name: 'Assissted Triceps Dip',
      category: WorkoutCategory.triceps,
      workoutImage: 'assets/workouts/tri/assisted_tri_dip.png',
    ),
    ExerciseModel(
      id: 15,
      name: 'Triceps Machine Dip',
      category: WorkoutCategory.triceps,
      workoutImage: 'assets/workouts/tri/machine_dip.png',
    ),
    ExerciseModel(
      id: 16,
      name: 'Single Arm Tricep Push Down',
      category: WorkoutCategory.triceps,
      workoutImage: 'assets/workouts/tri/single_tri_push_down.png',
    ),
    ExerciseModel(
      id: 17,
      name: 'Triceps Extention',
      category: WorkoutCategory.triceps,
      workoutImage: 'assets/workouts/tri/tricep_extention.png',
    ),
    ExerciseModel(
      id: 18,
      name: 'Triceps Push Down',
      category: WorkoutCategory.triceps,
      workoutImage: 'assets/workouts/tri/tricep_push_down.png',
    ),

    ExerciseModel(
      id: 19,
      name: 'Biceps Barbell Curl',
      category: WorkoutCategory.bicepes,
      workoutImage: 'assets/workouts/bicep/barbell_curl.png',
    ),
    ExerciseModel(
      id: 20,
      name: 'Bayesian Curl',
      category: WorkoutCategory.bicepes,
      workoutImage: 'assets/workouts/bicep/bayesian_curl.png',
    ),
    ExerciseModel(
      id: 21,
      name: 'Cable Hammer Curl',
      category: WorkoutCategory.bicepes,
      workoutImage: 'assets/workouts/bicep/hammer_curl_cable.png',
    ),
    ExerciseModel(
      id: 22,
      name: 'Preacher Curl',
      category: WorkoutCategory.bicepes,
      workoutImage: 'assets/workouts/bicep/preacher_curl.png',
    ),
    ExerciseModel(
      id: 23,
      name: 'Seated Incline Curl',
      category: WorkoutCategory.bicepes,
      workoutImage: 'assets/workouts/bicep/seated_incline_curl.png',
    ),
    ExerciseModel(
      id: 24,
      name: 'Face Pull',
      category: WorkoutCategory.shoulders,
      workoutImage: 'assets/workouts/shoulder/face_pull.png',
    ),
    ExerciseModel(
      id: 25,
      name: 'Lateral Raise (Cable)',
      category: WorkoutCategory.shoulders,
      workoutImage: 'assets/workouts/shoulder/lateral_raise_cable.png',
    ),
    ExerciseModel(
      id: 26,
      name: 'Lateral Raise (Dumbbell)',
      category: WorkoutCategory.shoulders,
      workoutImage: 'assets/workouts/shoulder/lateral_raise_dumbbell.png',
    ),
    ExerciseModel(
      id: 27,
      name: 'Lateral Raise (Machine)',
      category: WorkoutCategory.shoulders,
      workoutImage: 'assets/workouts/shoulder/lateral_raise_machine.png',
    ),
    ExerciseModel(
      id: 28,
      name: 'Reverse Fly (Machine)',
      category: WorkoutCategory.shoulders,
      workoutImage: 'assets/workouts/shoulder/reverse_fly_machine.png',
    ),
    ExerciseModel(
      id: 29,
      name: 'Shoulder Press (Barbell)',
      category: WorkoutCategory.shoulders,
      workoutImage: 'assets/workouts/shoulder/shoulder_barbell_press.png',
    ),
    ExerciseModel(
      id: 30,
      name: 'Shoulder Press (Dumbbell)',
      category: WorkoutCategory.shoulders,
      workoutImage: 'assets/workouts/shoulder/shoulder_dumbbell_press.png',
    ),
    ExerciseModel(
      id: 31,
      name: 'Shoulder Press (Machine)',
      category: WorkoutCategory.shoulders,
      workoutImage: 'assets/workouts/shoulder/shoulder_machine_press.png',
    ),

    ExerciseModel(
      id: 32,
      name: 'Abs Twist',
      category: WorkoutCategory.abs,
      workoutImage: 'assets/workouts/abs/abs_twist.png',
    ),
    ExerciseModel(
      id: 33,
      name: 'Decline Set-up',
      category: WorkoutCategory.abs,
      workoutImage: 'assets/workouts/abs/decline_setup.png',
    ),
    ExerciseModel(
      id: 34,
      name: 'Leg Raises',
      category: WorkoutCategory.abs,
      workoutImage: 'assets/workouts/abs/leg_raises.png',
    ),
    ExerciseModel(
      id: 35,
      name: 'Machine Abs Crunch',
      category: WorkoutCategory.abs,
      workoutImage: 'assets/workouts/abs/machine_abs_crunch.png',
    ),

    ExerciseModel(
      id: 36,
      name: 'Bulgarian Split Squat',
      category: WorkoutCategory.legs,
      workoutImage: 'assets/workouts/legs/bulgarian_split_squat.png',
    ),
    ExerciseModel(
      id: 37,
      name: 'Squat',
      category: WorkoutCategory.legs,
      workoutImage: 'assets/workouts/legs/squat.png',
    ),
    ExerciseModel(
      id: 38,
      name: 'Hack Squat',
      category: WorkoutCategory.legs,
      workoutImage: 'assets/workouts/legs/hack_squat.png',
    ),
    ExerciseModel(
      id: 39,
      name: 'Leg Press',
      category: WorkoutCategory.legs,
      workoutImage: 'assets/workouts/legs/leg_press.png',
    ),
    ExerciseModel(
      id: 40,
      name: 'Leg Extension',
      category: WorkoutCategory.legs,
      workoutImage: 'assets/workouts/legs/leg_extention.png',
    ),
    ExerciseModel(
      id: 41,
      name: 'Seated Leg Curl',
      category: WorkoutCategory.legs,
      workoutImage: 'assets/workouts/legs/seated_leg_curl.png',
    ),
    ExerciseModel(
      id: 42,
      name: 'Laying Leg Curl',
      category: WorkoutCategory.legs,
      workoutImage: 'assets/workouts/legs/laying_leg_curl.png',
    ),
    ExerciseModel(
      id: 43,
      name: 'Romanian Deadlift (RDL)',
      category: WorkoutCategory.legs,
      workoutImage: 'assets/workouts/legs/rdl.png',
    ),
    ExerciseModel(
      id: 44,
      name: 'Deadlift',
      category: WorkoutCategory.legs,
      workoutImage: 'assets/workouts/legs/deadlift.png',
    ),
    ExerciseModel(
      id: 45,
      name: 'Seated Calf Press',
      category: WorkoutCategory.legs,
      workoutImage: 'assets/workouts/legs/seated_calf_press.png',
    ),
    ExerciseModel(
      id: 46,
      name: 'Calf Raises',
      category: WorkoutCategory.legs,
      workoutImage: 'assets/workouts/legs/calf_raises.png',
    ),
    ExerciseModel(
      id: 47,
      name: 'Dumbbell Shrugs',
      category: WorkoutCategory.shoulders,
      workoutImage: 'assets/workouts/shoulder/dumbbell_shrug.png',
    ),
    ExerciseModel(
      id: 48,
      name: 'Machine Shrugs',
      category: WorkoutCategory.shoulders,
      workoutImage: 'assets/workouts/shoulder/machine_shrug.png',
    ),
    ExerciseModel(
      id: 49,
      name: 'Close Grip Lat Pulldown',
      category: WorkoutCategory.back,
      workoutImage: 'assets/workouts/back/close_grip_lat_pulldown.png',
    ),
  ];

  List<ExerciseModel> get exercises => List.unmodifiable(_exercises);
}
