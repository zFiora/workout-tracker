import 'package:hive/hive.dart';

class PrEventsRepository {
  static const String boxName = 'prEventsBox';

  Future<Box> _open() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<void> putEventsForHistoryKey(
    dynamic historyKey,
    List<Map<String, dynamic>> prEvents,
  ) async {
    final box = await _open();
    await box.put(historyKey, prEvents);
  }

  Future<void> deleteEventsForHistoryKey(dynamic historyKey) async {
    final box = await _open();
    await box.delete(historyKey);
  }

  Future<void> clearAll() async {
    final box = await _open();
    await box.clear();
  }

  /// Returns a Set of keys like: "$exerciseId:${performedAtMs}"
  /// Only includes kind == 'bestWeight' (same as your original logic).
  Future<Set<String>> loadBestWeightPrKeys(dynamic historyKey) async {
    final box = await _open();
    final raw = box.get(historyKey);

    if (raw is! List) return <String>{};

    final keys = <String>{};

    for (final e in raw) {
      if (e is! Map) continue;

      final exId = e['exerciseId'];
      final performedAt = e['performedAt'];
      final kind = e['kind'];

      if (exId is! int) continue;
      if (performedAt is! String) continue;
      if (kind != 'bestWeight') continue;

      DateTime? dt;
      try {
        dt = DateTime.parse(performedAt);
      } catch (_) {
        dt = null;
      }
      if (dt == null) continue;

      keys.add('$exId:${dt.millisecondsSinceEpoch}');
    }

    return keys;
  }

  bool isPr(Set<String> prKeys, int exId, DateTime setTs) {
    return prKeys.contains('$exId:${setTs.millisecondsSinceEpoch}');
  }
}
