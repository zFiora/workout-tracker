import 'package:hive/hive.dart';
import 'package:workout_tracker/home/measure/models/macro_profile.dart';


class MacrosProfileRepository {
  static const String boxName = 'macrosProfileBox';
  static const String key = 'profile';

  Box<MacroProfile> _box() => Hive.box<MacroProfile>(boxName);

  MacroProfile getProfile() {
    return _box().get(key) ?? MacroProfile.defaults;
  }

  Future<void> saveProfile(MacroProfile profile) async {
    await _box().put(key, profile);
  }
}
