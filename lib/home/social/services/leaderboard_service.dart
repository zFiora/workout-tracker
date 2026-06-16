import 'package:flutter/foundation.dart';
import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/core/auth_token.dart';

class LeaderboardService {
  final _client = ApiClient.instance;

  /// Friends ranked by currentStreak descending (includes self).
  Future<ApiResult<List<LeaderboardEntry>>> fetchStreakLeaderboard() async {
    if (!AuthToken.I.isValid) {
      return const ApiSuccess([]);
    }
    try {
      final result = await _client.get('/api/friends/leaderboard');
      return switch (result) {
        ApiSuccess(:final data) => ApiSuccess(
          (data as List)
              .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        ApiError(:final message) => ApiError(message),
      };
    } catch (e, st) {
      debugPrint('[Leaderboard] error: $e\n$st');
      return const ApiError('Could not load leaderboard.');
    }
  }

  /// All-time PR records for [exerciseId] (own records for now).
  Future<ApiResult<List<PrRecord>>> fetchExercisePrs(int exerciseId) async {
    if (!AuthToken.I.isValid) return const ApiSuccess([]);
    try {
      final result = await _client.get(
        '/api/pr-events',
        params: {'exerciseId': exerciseId},
      );
      return switch (result) {
        ApiSuccess(:final data) => ApiSuccess(
          (data as List)
              .map((e) => PrRecord.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        ApiError(:final message) => ApiError(message),
      };
    } catch (e, st) {
      debugPrint('[Leaderboard] fetchExercisePrs error: $e\n$st');
      return const ApiError('Could not load PRs.');
    }
  }
}

// ── Data models ──────────────────────────────────────────────────────────────

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.currentStreak,
    required this.bestStreak,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int currentStreak;
  final int bestStreak;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final display = json['displayName'] as String?;
    final username = json['username'] as String?;
    return LeaderboardEntry(
      userId: json['id'] as String? ?? '',
      displayName: (display?.isNotEmpty == true) ? display! : (username ?? ''),
      avatarUrl: json['avatarUrl'] as String?,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
    );
  }
}

class PrRecord {
  const PrRecord({
    required this.userId,
    required this.exerciseId,
    required this.weightKg,
    required this.reps,
    required this.achievedAt,
    required this.kind,
  });

  final String userId;
  final int exerciseId;
  final double weightKg;
  final int reps;
  final DateTime achievedAt;
  final String kind;

  factory PrRecord.fromJson(Map<String, dynamic> json) => PrRecord(
    userId: json['userId'] as String? ?? '',
    exerciseId: (json['exerciseId'] as num?)?.toInt() ?? 0,
    weightKg: (json['weight'] as num?)?.toDouble() ?? 0,
    reps: (json['reps'] as num?)?.toInt() ?? 0,
    achievedAt:
        DateTime.tryParse(json['performedAt'] as String? ?? '') ?? DateTime.now(),
    kind: json['kind'] as String? ?? '',
  );
}
