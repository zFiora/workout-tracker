import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/home/measure/models/macro_profile.dart';

void main() {
  group('MacroProfile.age', () {
    test('falls back to the legacy manual age when no DOB is set', () {
      final profile = MacroProfile(isMale: true, ageFallback: 42, activityFactor: 1.2);
      expect(profile.dateOfBirthUtc, isNull);
      expect(profile.age, 42);
    });

    test('is computed from DOB once set, ignoring the legacy fallback', () {
      final now = DateTime.now().toUtc();
      final twentyYearsAgo = DateTime.utc(now.year - 20, now.month, now.day);
      final profile = MacroProfile(
        isMale: true,
        ageFallback: 999, // must be ignored once a DOB exists
        activityFactor: 1.2,
        dateOfBirthUtc: twentyYearsAgo,
      );
      expect(profile.age, 20);
    });

    test("doesn't count this year's birthday if it hasn't happened yet", () {
      final now = DateTime.now().toUtc();
      // A birthday one day from now, 20 years ago — the birthday hasn't
      // occurred yet this year, so the age must still read 19.
      final future = now.add(const Duration(days: 1));
      final dob = DateTime.utc(future.year - 20, future.month, future.day);
      final profile = MacroProfile(isMale: true, ageFallback: 0, activityFactor: 1.2)
          .copyWith(dateOfBirthUtc: dob);
      expect(profile.age, 19);
    });

    test('counts the birthday once it has occurred this year', () {
      final now = DateTime.now().toUtc();
      final past = now.subtract(const Duration(days: 1));
      final dob = DateTime.utc(past.year - 20, past.month, past.day);
      final profile = MacroProfile(isMale: true, ageFallback: 0, activityFactor: 1.2)
          .copyWith(dateOfBirthUtc: dob);
      expect(profile.age, 20);
    });
  });

  group('MacroProfile.sex', () {
    test('defaults to unspecified, never guessed from isMale', () {
      final profile = MacroProfile(isMale: true, ageFallback: 25, activityFactor: 1.2);
      expect(profile.sex, Sex.unspecified);
    });

    test('withSex keeps the legacy isMale BMR flag in sync', () {
      final base = MacroProfile(isMale: true, ageFallback: 25, activityFactor: 1.2);

      final asFemale = base.withSex(Sex.female);
      expect(asFemale.sex, Sex.female);
      expect(asFemale.isMale, isFalse);

      final asMale = asFemale.withSex(Sex.male);
      expect(asMale.sex, Sex.male);
      expect(asMale.isMale, isTrue);
    });

    test('withSex(unspecified) leaves the BMR flag untouched', () {
      final base = MacroProfile(isMale: false, ageFallback: 25, activityFactor: 1.2);
      final unspecified = base.withSex(Sex.unspecified);
      expect(unspecified.sex, Sex.unspecified);
      expect(unspecified.isMale, isFalse);
    });
  });
}
