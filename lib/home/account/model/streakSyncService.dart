import 'package:flutter/foundation.dart';
import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/core/auth_token.dart';

class StreakSyncService {
  StreakSyncService({required this.userId});

  final String userId;
  final _client = ApiClient.instance;

  /// If the last workout was 3+ days ago, resets currentStreak to 0 on the server.
  Future<void> normalizeForToday(DateTime now) async {
    if (!AuthToken.I.isValid) return;
    final today = _dayOnly(now);

    final result = await _client.get('/api/users/me');
    if (result is! ApiSuccess<dynamic>) return;

    final data = result.data as Map<String, dynamic>;
    final int serverCurrent = (data['currentStreak'] as num?)?.toInt() ?? 0;
    final String? lastIso = data['lastWorkoutDate'] as String?;
    final DateTime? last = lastIso == null ? null : DateTime.tryParse(lastIso);
    final DateTime? lastDay = last == null ? null : _dayOnly(last);

    if (lastDay == null) return;
    final gap = today.difference(lastDay).inDays;

    if (gap >= 3 && serverCurrent != 0) {
      await _client.patch('/api/users/me', {'currentStreak': 0});
      if (kDebugMode) debugPrint('[StreakSync] normalize: gap=$gap -> reset currentStreak=0');
    }
  }

  /// Call after saving the first finished session of the day locally.
  Future<void> bumpIfFirstWorkoutToday(DateTime now) async {
    if (!AuthToken.I.isValid) return;
    final today = _dayOnly(now);

    final result = await _client.get('/api/users/me');
    if (result is! ApiSuccess<dynamic>) return;

    final data = result.data as Map<String, dynamic>;
    final int serverCurrent = (data['currentStreak'] as num?)?.toInt() ?? 0;
    final int serverBest = (data['bestStreak'] as num?)?.toInt() ?? 0;
    final String? lastIso = data['lastWorkoutDate'] as String?;
    final DateTime? last = lastIso == null ? null : DateTime.tryParse(lastIso);
    final DateTime? lastDay = last == null ? null : _dayOnly(last);

    if (lastDay != null && lastDay == today) return;

    int newCurrent;
    if (lastDay == null) {
      newCurrent = 1;
    } else {
      final gap = today.difference(lastDay).inDays;
      newCurrent = gap >= 3 ? 1 : serverCurrent + 1;
    }
    final int newBest = newCurrent > serverBest ? newCurrent : serverBest;

    await _client.patch('/api/users/me', {
      'currentStreak': newCurrent,
      'bestStreak': newBest,
      'lastWorkoutDate': today.toIso8601String(),
    });

    if (kDebugMode) {
      debugPrint('[StreakSync] bump -> current=$newCurrent best=$newBest');
    }
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
