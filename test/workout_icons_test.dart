import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/common/models/sex.dart';
import 'package:workout_tracker/common/theme/workout_icons.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';

void main() {
  group('WorkoutIcons.keyFromStored', () {
    test('passes logical keys through unchanged', () {
      expect(WorkoutIcons.keyFromStored('chest'), 'chest');
      expect(WorkoutIcons.keyFromStored('legs'), 'legs');
    });

    test('maps legacy emoji paths back to their key', () {
      expect(
        WorkoutIcons.keyFromStored('assets/workout_category/chest_emoji.png'),
        'chest',
      );
      expect(
        WorkoutIcons.keyFromStored(
            'assets/workout_category/muscular_forearms_emoji.png'),
        'forearms',
      );
      expect(
        WorkoutIcons.keyFromStored('assets/workout_category/bicep_emoji.png'),
        'biceps',
      );
    });

    test('returns null for anything unrecognised', () {
      expect(WorkoutIcons.keyFromStored('assets/custom/thing.png'), isNull);
    });
  });

  group('WorkoutIcons.assetForKey — gender switching', () {
    test('female uses the female asset set', () {
      expect(
        WorkoutIcons.assetForKey('back', Sex.female),
        'assets/workout_category/female/female_back.png',
      );
    });

    test('male uses the male asset set', () {
      expect(
        WorkoutIcons.assetForKey('legs', Sex.male),
        'assets/workout_category/male/male_quads.webp',
      );
    });

    test('unspecified uses the neutral emoji set', () {
      expect(
        WorkoutIcons.assetForKey('back', Sex.unspecified),
        'assets/workout_category/back_emoji.png',
      );
    });

    test('male chest uses the male asset', () {
      expect(
        WorkoutIcons.assetForKey('chest', Sex.male),
        'assets/workout_category/male/male_chest.png',
      );
    });

    test('female chest uses the female asset', () {
      expect(
        WorkoutIcons.assetForKey('chest', Sex.female),
        'assets/workout_category/female/female_chest.png',
      );
    });
  });

  group('WorkoutIcons.resolve — end to end', () {
    test('legacy stored path re-themes to the current gender', () {
      // An old template that stored the neutral chest path now shows the
      // female chest art for a female user.
      expect(
        WorkoutIcons.resolve(
          'assets/workout_category/back_emoji.png',
          Sex.female,
        ),
        'assets/workout_category/female/female_back.png',
      );
    });

    test('unknown/custom paths are returned unchanged', () {
      expect(
        WorkoutIcons.resolve('assets/custom/logo.png', Sex.male),
        'assets/custom/logo.png',
      );
    });
  });

  group('WorkoutCategoryIcon.iconKey', () {
    test('maps each category to its logical key (biceps spelling normalised)',
        () {
      expect(WorkoutCategory.bicepes.iconKey, 'biceps');
      expect(WorkoutCategory.chest.iconKey, 'chest');
      expect(WorkoutCategory.legs.iconKey, 'legs');
      expect(WorkoutCategory.forearms.iconKey, 'forearms');
    });

    test('every category key resolves to a real asset for every sex', () {
      for (final c in WorkoutCategory.values) {
        for (final s in Sex.values) {
          final asset = WorkoutIcons.assetForKey(c.iconKey, s);
          expect(asset, isNotEmpty);
          expect(asset.startsWith('assets/workout_category/'), isTrue);
        }
      }
    });
  });
}
