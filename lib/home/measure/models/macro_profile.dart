import 'package:hive/hive.dart';

part 'macro_profile.g.dart';

@HiveType(typeId: 32) // ✅ make sure 32 is not used in your app
class MacroProfile extends HiveObject {
  @HiveField(0)
  final bool isMale;

  @HiveField(1)
  final int age;

  @HiveField(2)
  final double activityFactor; // 1.2 / 1.375 / 1.55 / 1.725 / 1.9

   MacroProfile({
    required this.isMale,
    required this.age,
    required this.activityFactor,
  });

  MacroProfile copyWith({
    bool? isMale,
    int? age,
    double? activityFactor,
  }) {
    return MacroProfile(
      isMale: isMale ?? this.isMale,
      age: age ?? this.age,
      activityFactor: activityFactor ?? this.activityFactor,
    );
  }

  static final defaults = MacroProfile(isMale: true, age: 25, activityFactor: 1.375);
}
