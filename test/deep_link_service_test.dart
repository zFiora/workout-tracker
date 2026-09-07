import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/core/services/deep_link_service.dart';

void main() {
  group('DeepLinkService.resetTokenFrom', () {
    test('extracts the token from a valid reset link (host form)', () {
      final uri = Uri.parse('workouttracker://reset-password?token=ABC123');
      expect(DeepLinkService.resetTokenFrom(uri), 'ABC123');
    });

    test('extracts the token when reset-password is a path segment', () {
      final uri = Uri.parse('workouttracker://app/reset-password?token=XYZ');
      expect(DeepLinkService.resetTokenFrom(uri), 'XYZ');
    });

    test('trims surrounding whitespace on the token', () {
      final uri = Uri.parse('workouttracker://reset-password?token=%20abc%20');
      expect(DeepLinkService.resetTokenFrom(uri), 'abc');
    });

    test('is case-insensitive on the scheme', () {
      final uri = Uri.parse('WorkoutTracker://reset-password?token=T');
      expect(DeepLinkService.resetTokenFrom(uri), 'T');
    });

    test('rejects a different scheme', () {
      final uri = Uri.parse('https://reset-password?token=ABC');
      expect(DeepLinkService.resetTokenFrom(uri), isNull);
    });

    test('rejects a non-reset host on the right scheme', () {
      final uri = Uri.parse('workouttracker://open-workout?token=ABC');
      expect(DeepLinkService.resetTokenFrom(uri), isNull);
    });

    test('rejects a reset link with no token', () {
      final uri = Uri.parse('workouttracker://reset-password');
      expect(DeepLinkService.resetTokenFrom(uri), isNull);
    });

    test('rejects a reset link with an empty token', () {
      final uri = Uri.parse('workouttracker://reset-password?token=');
      expect(DeepLinkService.resetTokenFrom(uri), isNull);
    });
  });
}
