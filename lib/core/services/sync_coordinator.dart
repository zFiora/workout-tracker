import 'package:flutter/foundation.dart';
import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/core/auth_token.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

/// Orchestrates syncing local Hive data to the .NET backend.
///
/// All methods are best-effort — errors are silently swallowed so the
/// local Hive save always succeeds regardless of network state.
class SyncCoordinator {
  final _client = ApiClient.instance;

  // ── History ──────────────────────────────────────────────────────────────

  Future<void> pushWorkoutEntry(WorkoutHistoryEntry entry) async {
    if (!AuthToken.I.isValid) return;
    final result = await _client.post('/api/workouts', entry.toJson());
    if (result.isError && kDebugMode) {
      debugPrint('[Sync] pushWorkoutEntry failed: ${result.errorOrNull}');
    }
  }

  Future<void> pushPrEvents(List<Map<String, dynamic>> events) async {
    if (!AuthToken.I.isValid) return;
    for (final event in events) {
      final result = await _client.post('/api/pr-events', event);
      if (result.isError && kDebugMode) {
        debugPrint('[Sync] pushPrEvent failed: ${result.errorOrNull}');
      }
    }
  }

  // ── Leaderboard ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    if (!AuthToken.I.isValid) return [];
    final result = await _client.get('/api/friends/leaderboard');
    if (result.isError) return [];
    return List<Map<String, dynamic>>.from(
      (result as ApiSuccess).data as List? ?? [],
    );
  }

  // ── Templates ────────────────────────────────────────────────────────────

  Future<bool> shareTemplate(Map<String, dynamic> templateJson) async {
    if (!AuthToken.I.isValid) return false;
    final result = await _client.post(
      '/api/templates',
      {...templateJson, 'isPublic': true},
    );
    return result.isSuccess;
  }
}
