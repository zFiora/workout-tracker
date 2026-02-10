import 'package:hive/hive.dart';
import '../models/measurement_entry.dart';

class MeasuresRepository {
  static const String boxName = 'measurementsBox';

  Future<Box<MeasurementEntry>> _box() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<MeasurementEntry>(boxName);
    }
    return Hive.box<MeasurementEntry>(boxName);
  }

  /// Returns entries UNSORTED. ViewModel decides ordering.
  Future<List<MeasurementEntry>> getAll() async {
    final box = await _box();
    return box.values.toList();
  }

  /// Enforce 1 entry per local day.
  Future<void> upsert(MeasurementEntry entry) async {
    final box = await _box();

    final existingKey = box.keys.cast<dynamic>().firstWhere((k) {
      final e = box.get(k);
      if (e == null) return false;
      return _isSameLocalDay(e.date.toLocal(), entry.date.toLocal());
    }, orElse: () => null);

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
