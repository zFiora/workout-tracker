import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/home/exercises/widgets/exercise_image.dart';

void main() {
  group('exerciseImageProvider (custom-photo vs asset resolution)', () {
    test('empty path → null (renders a placeholder, not a broken image)', () {
      expect(exerciseImageProvider(''), isNull);
    });

    test('bundled asset path → AssetImage', () {
      final p = exerciseImageProvider('assets/workouts/chest/bench.png');
      expect(p, isA<AssetImage>());
      expect((p! as AssetImage).assetName, 'assets/workouts/chest/bench.png');
    });

    test('absolute file path (custom exercise photo) → FileImage', () {
      // This is the case the bug missed: session/history called Image.asset on
      // a file path. The provider must pick FileImage instead.
      final p = exerciseImageProvider(
          '/data/user/0/com.app/app_flutter/exercise_images/abc.jpg');
      expect(p, isA<FileImage>());
    });
  });
}
