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

  /// Friends (incl. self) ranked by their best lift for a single exercise.
  ///
  /// Backend contract expected at `GET /api/exercises/{exerciseId}/friends-ranking`
  /// (mirrors the existing `/api/workouts/{templateId}/friends-ranking`
  /// convention). Each item: user identity + best `weight`/`reps` and,
  /// optionally, a server-computed `oneRepMax`. Returns an empty list for
  /// offline / signed-out users rather than an error.
  Future<ApiResult<List<ExerciseLeaderboardEntry>>> fetchExerciseFriendsRanking(
    int exerciseId,
  ) async {
    if (!AuthToken.I.isValid) return const ApiSuccess([]);
    try {
      final result =
          await _client.get('/api/exercises/$exerciseId/friends-ranking');
      return switch (result) {
        ApiSuccess(:final data) => ApiSuccess(
            (data as List)
                .map((e) => ExerciseLeaderboardEntry.fromJson(
                    e as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => b.score.compareTo(a.score)),
          ),
        ApiError(:final message) => ApiError(message),
      };
    } catch (e, st) {
      debugPrint('[Leaderboard] fetchExerciseFriendsRanking error: $e\n$st');
      return const ApiError('Could not load ranking.');
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
    required this.avatarBase64,
    required this.currentStreak,
    required this.bestStreak,
  });

  final String userId;
  final String displayName;

  /// Raw base64-encoded avatar image (no data-URI prefix), or null.
  final String? avatarBase64;
  final int currentStreak;
  final int bestStreak;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final display = json['displayName'] as String?;
    final username = json['username'] as String?;
    return LeaderboardEntry(
      userId: json['id'] as String? ?? '',
      displayName: (display?.isNotEmpty == true) ? display! : (username ?? ''),
      avatarBase64: json['avatarBase64'] as String?,
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

/// One friend's best effort on a single exercise, used to rank the
/// per-exercise leaderboard.
class ExerciseLeaderboardEntry {
  const ExerciseLeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.avatarBase64,
    required this.weightKg,
    required this.reps,
    required this.oneRepMax,
    required this.achievedAt,
    required this.isMe,
  });

  final String userId;
  final String displayName;

  /// Raw base64-encoded avatar image (no data-URI prefix), or null.
  final String? avatarBase64;
  final double weightKg;
  final int reps;

  /// Server-provided estimate when present, otherwise an Epley estimate
  /// computed from [weightKg]/[reps]. Also the ranking key ([score]).
  final double oneRepMax;
  final DateTime? achievedAt;
  final bool isMe;

  /// Ranking key. Uses estimated 1RM so a heavy single and a lighter set
  /// for reps compare fairly.
  double get score => oneRepMax;

  factory ExerciseLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final display = json['displayName'] as String?;
    final username = json['username'] as String?;
    final weight = (json['weight'] as num?)?.toDouble() ??
        (json['weightKg'] as num?)?.toDouble() ??
        0;
    final reps = (json['reps'] as num?)?.toInt() ?? 0;
    final serverOrm =
        (json['oneRepMax'] ?? json['estimatedOneRepMax']) as num?;
    return ExerciseLeaderboardEntry(
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      displayName: (display?.isNotEmpty == true)
          ? display!
          : (username?.isNotEmpty == true ? username! : 'Unknown'),
      avatarBase64: json['avatarBase64'] as String?,
      weightKg: weight,
      reps: reps,
      // Epley: weight * (1 + reps/30). A single rep returns the weight itself.
      oneRepMax: serverOrm?.toDouble() ?? weight * (1 + reps / 30.0),
      achievedAt: DateTime.tryParse(
        json['achievedAt'] as String? ?? json['performedAt'] as String? ?? '',
      ),
      isMe: json['isMe'] as bool? ?? false,
    );
  }
}
