import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_config.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

/// Orchestrates syncing local Hive data to the PocketBase backend.
///
/// Swap point: replace [ApiClient.instance] calls with your own HTTP client
/// (e.g. Dio) if you move away from PocketBase.
///
/// Current sync surface:
///   • Workout history entries  → [ApiConfig.colWorkouts]
///   • PR events                → [ApiConfig.colPrEvents]
///   • Templates (future)       → [ApiConfig.colTemplates]
class SyncCoordinator {
  SyncCoordinator({required this.pb, required this.userId});

  final PocketBase pb;
  final String userId;

  final _client = ApiClient.instance;

  // ── History ──────────────────────────────────────────────────────────────

  /// Push a single finished session to the server.
  /// Safe to call even when offline — errors are silently swallowed so the
  /// local save always succeeds regardless of network state.
  Future<void> pushWorkoutEntry(WorkoutHistoryEntry entry) async {
    final body = {
      'user': userId,
      ...entry.toJson(),
    };
    final result = await _client.create(ApiConfig.colWorkouts, body);
    if (result.isError && kDebugMode) {
      debugPrint('[Sync] pushWorkoutEntry failed: ${result.errorOrNull}');
    }
  }

  /// Push a batch of PR events produced at the end of a session.
  Future<void> pushPrEvents(List<Map<String, dynamic>> events) async {
    for (final event in events) {
      final body = {'user': userId, ...event};
      final result = await _client.create(ApiConfig.colPrEvents, body);
      if (result.isError && kDebugMode) {
        debugPrint('[Sync] pushPrEvent failed: ${result.errorOrNull}');
      }
    }
  }

  // ── Leaderboard ──────────────────────────────────────────────────────────

  /// Fetch friends ordered by current streak descending.
  /// Returns a list of user records with streak fields.
  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    final result = await _client.list(
      ApiConfig.colUsers,
      sort: '-currentStreak',
      filter: 'friends.user ?= "$userId"',
      perPage: 50,
    );
    if (result.isError) return [];
    return result.dataOrNull
            ?.map((r) => {
                  'id': r.id,
                  'name': r.getStringValue('name'),
                  'displayName': r.getStringValue('displayName'),
                  'avatar': r.getStringValue('avatar'),
                  'currentStreak': r.getIntValue('currentStreak'),
                  'bestStreak': r.getIntValue('bestStreak'),
                })
            .toList() ??
        [];
  }

  // ── Templates (future) ───────────────────────────────────────────────────

  /// Share a template publicly so friends can clone it.
  Future<bool> shareTemplate(Map<String, dynamic> templateJson) async {
    final body = {'user': userId, ...templateJson, 'isPublic': true};
    final result = await _client.create(ApiConfig.colTemplates, body);
    return result.isSuccess;
  }
}
