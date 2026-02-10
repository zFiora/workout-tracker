abstract class PrEventsRepository {
  /// Raw persisted PR events for a specific history entry.
  /// Storage format stays List<Map<String, dynamic>> for now.
  Future<List<Map<String, dynamic>>> loadEventsForHistoryKey(dynamic historyKey);

  Future<void> putEventsForHistoryKey(
    dynamic historyKey,
    List<Map<String, dynamic>> prEvents,
  );

  Future<void> deleteEventsForHistoryKey(dynamic historyKey);

  Future<void> clearAll();
}

class PrEventKey {
  static String of(int exId, DateTime performedAt) =>
      '$exId:${performedAt.millisecondsSinceEpoch}';
}
