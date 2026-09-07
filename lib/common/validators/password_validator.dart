/// Single source of truth for the app's password policy — used by
/// registration, change-password, and reset-password so the three forms
/// can't silently drift out of sync with each other or with the backend's
/// own rule (min 8 characters, enforced server-side on register/change).
class PasswordValidator {
  PasswordValidator._();

  static const minLength = 8;

  /// Returns a form-field error message, or null if valid.
  static String? validate(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) return 'Min $minLength characters';
    return null;
  }

  /// Returns a form-field error message, or null if [confirm] matches
  /// [password].
  static String? validateConfirmation(String? confirm, String password) {
    if (confirm == null || confirm.isEmpty) return 'Confirm your password';
    if (confirm != password) return 'Passwords do not match';
    return null;
  }
}
