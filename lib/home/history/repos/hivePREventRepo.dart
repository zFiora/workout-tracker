import 'package:hive/hive.dart';
import 'package:workout_tracker/home/history/repos/PREventRepository.dart';

class HivePrEventsRepository implements PrEventsRepository {
  HivePrEventsRepository({String boxName = 'prEventsBox'}) : _boxName = boxName;

  final String _boxName;

  Future<Box> _open() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  @override
  Future<void> putEventsForHistoryKey(
    dynamic historyKey,
    List<Map<String, dynamic>> prEvents,
  ) async {
    final box = await _open();
    await box.put(historyKey, prEvents);
  }

  @override
  Future<void> deleteEventsForHistoryKey(dynamic historyKey) async {
    final box = await _open();
    await box.delete(historyKey);
  }

  @override
  Future<void> clearAll() async {
    final box = await _open();
    await box.clear();
  }

  @override
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

      final dt = DateTime.tryParse(performedAt);
      if (dt == null) continue;

      keys.add(PrEventKey.of(exId, dt));
    }

    return keys;
  }

  @override
  bool isPr(Set<String> prKeys, int exId, DateTime setTs) {
    return prKeys.contains(PrEventKey.of(exId, setTs));
  }
}
