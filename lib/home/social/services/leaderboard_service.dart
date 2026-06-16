import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:workout_tracker/core/api/api_config.dart';
import 'package:workout_tracker/core/api/api_result.dart';

/// Fetches leaderboard + friend PR data from PocketBase.
///
/// Swap point: replace PocketBase calls with any REST/GraphQL client
/// by changing the implementation of each method while keeping the signature.
class LeaderboardService {
  LeaderboardService(this._pb);
  final PocketBase _pb;

  /// Friends ranked by [currentStreak] descending.
  Future<ApiResult<List<LeaderboardEntry>>> fetchStreakLeaderboard(
    String currentUserId,
  ) async {
    try {
      final page = await _pb.collection(ApiConfig.colUsers).getList(
        perPage: 50,
        sort: '-currentStreak',
      );

      final entries = page.items
          .map((r) => LeaderboardEntry.fromRecord(r))
          .toList();

      return ApiSuccess(entries);
    } catch (e, st) {
      debugPrint('[Leaderboard] fetchStreakLeaderboard error: $e\n$st');
      return ApiError('Could not load leaderboard.', cause: e);
    }
  }

  /// All-time PR records for [exerciseId] across friends (for comparison).
  Future<ApiResult<List<PrRecord>>> fetchFriendPrs(
    String exerciseId,
    String currentUserId,
  ) async {
    try {
      final page = await _pb.collection(ApiConfig.colPrEvents).getList(
        perPage: 100,
        sort: '-weight',
        filter: 'exerciseId = "$exerciseId"',
        expand: 'user',
      );

      final records = page.items.map(PrRecord.fromRecord).toList();
      return ApiSuccess(records);
    } catch (e, st) {
      debugPrint('[Leaderboard] fetchFriendPrs error: $e\n$st');
      return ApiError('Could not load PRs.', cause: e);
    }
  }
}

// ── Data models returned by LeaderboardService ──────────────────────────────

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

  factory LeaderboardEntry.fromRecord(RecordModel r) {
    final avatar = r.getStringValue('avatar');
    return LeaderboardEntry(
      userId: r.id,
      displayName:
          r.getStringValue('displayName').isNotEmpty
              ? r.getStringValue('displayName')
              : r.getStringValue('name'),
      avatarUrl: avatar.isNotEmpty ? avatar : null,
      currentStreak: r.getIntValue('currentStreak'),
      bestStreak: r.getIntValue('bestStreak'),
    );
  }
}

class PrRecord {
  const PrRecord({
    required this.userId,
    required this.displayName,
    required this.exerciseId,
    required this.weightKg,
    required this.reps,
    required this.achievedAt,
  });

  final String userId;
  final String displayName;
  final String exerciseId;
  final double weightKg;
  final int reps;
  final DateTime achievedAt;

  factory PrRecord.fromRecord(RecordModel r) {
    final expandedUser = r.get<RecordModel?>('expand.user');
    return PrRecord(
      userId: r.getStringValue('user'),
      displayName:
          expandedUser?.getStringValue('displayName') ??
          expandedUser?.getStringValue('name') ??
          'Unknown',
      exerciseId: r.getStringValue('exerciseId'),
      weightKg: (r.data['weight'] as num?)?.toDouble() ?? 0,
      reps: r.getIntValue('reps'),
      achievedAt: DateTime.tryParse(r.getStringValue('created')) ?? DateTime.now(),
    );
  }
}
