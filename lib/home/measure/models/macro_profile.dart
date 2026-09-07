import 'package:hive/hive.dart';
import 'package:workout_tracker/common/models/sex.dart';

export 'package:workout_tracker/common/models/sex.dart' show Sex;

part 'macro_profile.g.dart';

@HiveType(typeId: 32) // ✅ make sure 32 is not used in your app
class MacroProfile extends HiveObject {
  /// Legacy BMR sex flag. Kept only because it's the field the backend's
  /// `/api/macro-profile` contract already accepts (`isMale: bool`) and
  /// because pre-existing Hive rows have it — [sex] is the field the UI
  /// reads/writes now; `setSex` keeps this mirror in sync so the wire format
  /// and the Mifflin-St Jeor formula don't need to change. Do not set this
  /// directly outside of `copyWith`/`setSex`.
  @HiveField(0)
  final bool isMale;

  /// Legacy manually-entered age, used only as a fallback for accounts that
  /// haven't set [dateOfBirthUtc] yet. Once a DOB is set, [age] is always
  /// computed from it and this value is ignored.
  @HiveField(1)
  final int ageFallback;

  @HiveField(2)
  final double activityFactor; // 1.2 / 1.375 / 1.55 / 1.725 / 1.9

  /// Additive field — absent (null) on every pre-existing Hive row, so old
  /// data reads back fine and nothing is silently invented for it.
  @HiveField(3)
  final Sex? sexValue;

  /// Stored as UTC midnight. Additive field, same backward-compat note as
  /// [sexValue].
  @HiveField(4)
  final DateTime? dateOfBirthUtc;

  MacroProfile({
    required this.isMale,
    required this.ageFallback,
    required this.activityFactor,
    this.sexValue,
    this.dateOfBirthUtc,
  });

  /// Sex for profile/theming purposes. Never inferred from [isMale] — a
  /// pre-existing account whose [isMale] happens to be `true` (the old
  /// default) hasn't necessarily ever told us their sex.
  Sex get sex => sexValue ?? Sex.unspecified;

  /// Age computed from [dateOfBirthUtc] (correctly accounting for whether
  /// this year's birthday has happened yet). Falls back to the legacy
  /// manually-entered value for accounts that haven't set a DOB.
  int get age {
    final dob = dateOfBirthUtc;
    if (dob == null) return ageFallback;
    final now = DateTime.now().toUtc();
    int computed = now.year - dob.year;
    final hadBirthdayThisYear = now.month > dob.month ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthdayThisYear) computed--;
    return computed;
  }

  MacroProfile copyWith({
    bool? isMale,
    int? age,
    double? activityFactor,
    Sex? sexValue,
    DateTime? dateOfBirthUtc,
    bool clearDateOfBirth = false,
  }) {
    return MacroProfile(
      isMale: isMale ?? this.isMale,
      ageFallback: age ?? ageFallback,
      activityFactor: activityFactor ?? this.activityFactor,
      sexValue: sexValue ?? this.sexValue,
      dateOfBirthUtc:
          clearDateOfBirth ? null : (dateOfBirthUtc ?? this.dateOfBirthUtc),
    );
  }

  /// Sets sex from the profile UI. Keeps the legacy [isMale] BMR flag (the
  /// only sex signal the backend currently accepts) in sync so the two
  /// never disagree — [sexValue] stays the single field the rest of the app
  /// reads. `unspecified` leaves the BMR flag as-is (Mifflin-St Jeor needs a
  /// binary input; there's nothing sensible to switch it to).
  MacroProfile withSex(Sex value) {
    final nextIsMale = switch (value) {
      Sex.male => true,
      Sex.female => false,
      Sex.unspecified => isMale,
    };
    return copyWith(sexValue: value, isMale: nextIsMale);
  }

  MacroProfile withDateOfBirth(DateTime dobLocal) {
    final utcMidnight =
        DateTime.utc(dobLocal.year, dobLocal.month, dobLocal.day);
    return copyWith(dateOfBirthUtc: utcMidnight);
  }

  static final defaults =
      MacroProfile(isMale: true, ageFallback: 25, activityFactor: 1.375);
}
