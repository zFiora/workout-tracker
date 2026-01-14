import 'package:hive/hive.dart';
import '../models/measurement_entry.dart';

class MeasuresRepository {
  static const String boxName = 'measurementsBox';

  Future<Box<MeasurementEntry>> _box() async {
    return Hive.openBox<MeasurementEntry>(boxName);
  }

  Future<List<MeasurementEntry>> getAll() async {
    final box = await _box();
    final list = box.values.toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<void> upsert(MeasurementEntry entry) async {
    final box = await _box();

    // Enforce 1 entry per day (local day), replace if same day exists
    final existingKey = box.keys.cast<dynamic>().firstWhere(
      (k) {
        final e = box.get(k);
        if (e == null) return false;
        return _isSameLocalDay(e.date.toLocal(), entry.date.toLocal());
      },
      orElse: () => null,
    );

    if (existingKey != null) {
      await box.put(existingKey, entry);
    } else {
      await box.add(entry);
    }
  }

  Future<void> deleteById(String id) async {
    final box = await _box();
    final key = box.keys.cast<dynamic>().firstWhere(
      (k) => box.get(k)?.id == id,
      orElse: () => null,
    );
    if (key != null) {
      await box.delete(key);
    }
  }

  bool _isSameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
