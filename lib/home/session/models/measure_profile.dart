import 'package:hive/hive.dart';

part 'measure_profile.g.dart';

@HiveType(typeId: 31) // ✅ unique typeId (make sure 31 not used)
class MeasureProfile extends HiveObject {
  @HiveField(0)
  final double? heightCm;

  MeasureProfile({this.heightCm});

  MeasureProfile copyWith({double? heightCm}) {
    return MeasureProfile(heightCm: heightCm ?? this.heightCm);
  }
}
