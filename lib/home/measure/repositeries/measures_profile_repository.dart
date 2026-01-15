import 'package:hive/hive.dart';
import 'package:workout_tracker/home/measure/models/measure_profile.dart';


class MeasuresProfileRepository {
  static const String boxName = 'measureProfileBox';
  static const String key = 'profile';

  Box<MeasureProfile> _box() => Hive.box<MeasureProfile>(boxName);

  MeasureProfile getProfile() {
    return _box().get(key) ?? MeasureProfile(heightCm: null);
  }

  Future<void> saveProfile(MeasureProfile profile) async {
    await _box().put(key, profile);
  }
}
