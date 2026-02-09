import 'package:hive/hive.dart';

abstract class PrEventsRepository {
  Future<Set<String>> loadBestWeightPrKeys(dynamic historyKey);

  Future<void> putEventsForHistoryKey(
    dynamic historyKey,
    List<Map<String, dynamic>> prEvents,
  );

  Future<void> deleteEventsForHistoryKey(dynamic historyKey);

  Future<void> clearAll();

  bool isPr(Set<String> prKeys, int exId, DateTime setTs);
}

class PrEventKey {
  static String of(int exId, DateTime performedAt) =>
      '$exId:${performedAt.millisecondsSinceEpoch}';
}
