import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/recap/workout_recap.dart';
import 'package:workout_tracker/home/session/recap/workout_recap_store.dart';
import 'package:workout_tracker/home/session/services/muscle_summary_service.dart';

/// Freezes and saves the recap for a workout that was just saved to history.
///
/// Never throws: a failure here must not affect the (already completed)
/// workout save. Returns the recap that was shown/stored, or null if the
/// muscle summary couldn't be computed at all.
Future<WorkoutRecap?> createRecapForSavedWorkout(
  WorkoutHistoryEntry entry, {
  required int prCount,
  WorkoutRecapStore? store,
  MuscleSummary Function(WorkoutHistoryEntry) computeSummary =
      computeMuscleSummary,
  DateTime Function() now = DateTime.now,
}) async {
  final WorkoutRecap recap;
  try {
    recap = WorkoutRecap(
      workoutId: entry.id,
      summary: computeSummary(entry),
      prCount: prCount,
      createdAt: now(),
    );
  } catch (e) {
    debugPrint('[WorkoutRecap] summary failed for ${entry.id}: $e');
    return null;
  }
  try {
    await (store ?? WorkoutRecapStore.I).put(recap);
  } catch (e) {
    // Still show it this time; it just won't be available from History.
    debugPrint('[WorkoutRecap] could not persist recap for ${entry.id}: $e');
  }
  return recap;
}
