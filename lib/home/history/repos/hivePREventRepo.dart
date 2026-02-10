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
  Future<List<Map<String, dynamic>>> loadEventsForHistoryKey(
    dynamic historyKey,
  ) async {
    final box = await _open();
    final raw = box.get(historyKey);

    if (raw is! List) return const <Map<String, dynamic>>[];

    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        out.add(e);
      } else if (e is Map) {
        // Defensive: coerce Map<dynamic,dynamic> to Map<String,dynamic>
        out.add(Map<String, dynamic>.from(e));
      }
    }
    return out;
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
}
