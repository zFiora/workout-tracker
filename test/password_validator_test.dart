import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/common/validators/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    test('rejects empty password', () {
      expect(PasswordValidator.validate(''), isNotNull);
      expect(PasswordValidator.validate(null), isNotNull);
    });

    test('rejects passwords shorter than the minimum', () {
      expect(PasswordValidator.validate('short1'), isNotNull);
    });

    test('accepts a password meeting the minimum length', () {
      expect(PasswordValidator.validate('longenough1'), isNull);
    });

    test('validateConfirmation requires an exact match', () {
      expect(PasswordValidator.validateConfirmation('abc', 'abc'), isNull);
      expect(PasswordValidator.validateConfirmation('abc', 'abd'), isNotNull);
      expect(PasswordValidator.validateConfirmation('', 'abd'), isNotNull);
    });
  });
}
