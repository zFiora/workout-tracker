import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

/// Thrown when the server rejects a saved reconciliation cursor (e.g. it's too
/// old / no longer valid). The reconciler catches this, drops the cursor, and
/// restarts a full backfill from scratch.
class CursorInvalidException implements Exception {
  CursorInvalidException(this.message);
  final String message;
  @override
  String toString() => 'CursorInvalidException: $message';
}

/// One change in the history change-feed: either an upsert (a full session) or
/// a tombstone (`deleted == true`, meaning remove it locally).
class RemoteSessionChange {
  const RemoteSessionChange({
    required this.id,
    required this.deleted,
    this.entry,
  });

  final String id;
  final bool deleted;
  final WorkoutHistoryEntry? entry; // null for tombstones

  factory RemoteSessionChange.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?) ?? '';
    final deletedAt = json['deletedAt'] as String?;
    final deleted = deletedAt != null && deletedAt.isNotEmpty;
    return RemoteSessionChange(
      id: id,
      deleted: deleted,
      entry: (deleted || id.isEmpty)
          ? null
          : WorkoutHistoryEntry.fromJson(json),
    );
  }
}

/// One page of the `/history` change-feed.
class RemoteSessionPage {
  const RemoteSessionPage({
    required this.changes,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<RemoteSessionChange> changes;
  final String? nextCursor;
  final bool hasMore;

  /// Tolerant of the exact envelope shape: accepts a `{sessions|items|history}`
  /// list with `{nextCursor|cursor|next}` + optional `hasMore`, or a bare list
  /// (treated as a single, final page).
  factory RemoteSessionPage.fromResponse(dynamic data) {
    if (data is List) {
      return RemoteSessionPage(
        changes: data
            .map((e) =>
                RemoteSessionChange.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        nextCursor: null,
        hasMore: false,
      );
    }

    final map = Map<String, dynamic>.from(data as Map);
    final rawList = (map['sessions'] ?? map['items'] ?? map['history'] ?? const [])
        as List;
    final changes = rawList
        .map((e) =>
            RemoteSessionChange.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    var next = (map['nextCursor'] ?? map['cursor'] ?? map['next']) as String?;
    if (next != null && next.isEmpty) next = null;

    final hasMore = map['hasMore'] as bool? ??
        (next != null && changes.isNotEmpty);

    return RemoteSessionPage(
      changes: changes,
      nextCursor: next,
      hasMore: hasMore,
    );
  }
}

/// Talks to the consolidated `/api/workout-sessions` backend.
///
/// Sessions are identified by a client-generated UUID and upserted, so pushing
/// the same session twice never duplicates it.
class WorkoutSessionsApiService {
  final _client = ApiClient.instance;

  /// Batch idempotent upsert. Returns the ids the server confirmed as saved
  /// (already-present ids are included; malformed ones are omitted, signalling
  /// the client to retry them).
  Future<Set<String>> pushSessions(List<WorkoutHistoryEntry> sessions) async {
    if (sessions.isEmpty) return <String>{};
    final result = await _client.post('/api/workout-sessions/sync', {
      'sessions': sessions.map((s) => s.toJson()).toList(),
    });
    return switch (result) {
      ApiSuccess(:final data) =>
        ((data['savedIds'] as List?) ?? const []).cast<String>().toSet(),
      ApiError(:final message) => throw Exception(message),
    };
  }

  /// The caller's sessions whose endedAt falls within the last [sinceDays].
  Future<List<WorkoutHistoryEntry>> fetchRecent({int sinceDays = 7}) async {
    final result = await _client.get(
      '/api/workout-sessions',
      params: {'sinceDays': sinceDays},
    );
    return switch (result) {
      ApiSuccess(:final data) => (data as List)
          .cast<Map<String, dynamic>>()
          .map(WorkoutHistoryEntry.fromJson)
          .toList(),
      ApiError(:final message) => throw Exception(message),
    };
  }

  /// One page of the full history change-feed (used for backfill + incremental
  /// reconciliation). `includeDeleted` brings tombstones through so client-side
  /// deletes made on other devices propagate here.
  ///
  /// Throws [CursorInvalidException] when the server rejects [cursor] (a 4xx),
  /// signalling the caller to reset to a full backfill.
  Future<RemoteSessionPage> fetchHistoryPage({
    String? cursor,
    int limit = 200,
    bool includeDeleted = true,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'includeDeleted': includeDeleted,
    };
    if (cursor != null && cursor.isNotEmpty) params['cursor'] = cursor;

    final result =
        await _client.get('/api/workout-sessions/history', params: params);
    return switch (result) {
      ApiSuccess(:final data) => RemoteSessionPage.fromResponse(data),
      ApiError(:final statusCode, :final message) => throw ((cursor != null &&
                  cursor.isNotEmpty &&
                  (statusCode == 400 ||
                      statusCode == 404 ||
                      statusCode == 410))
              ? CursorInvalidException(message)
              : Exception(message)),
    };
  }

  /// Soft-deletes a session server-side. A 404 is treated as success (the
  /// session is already gone), so a retried offline delete can't get stuck.
  Future<void> deleteSession(String id) async {
    final result = await _client.delete('/api/workout-sessions/$id');
    if (result is ApiError) {
      final err = result as ApiError;
      if (err.statusCode == 404) return; // already deleted — fine
      throw Exception(err.message);
    }
  }
}
