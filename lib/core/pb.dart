// Compatibility shim — all real auth logic has moved to AuthToken.
// This file exists only so stale imports compile while the migration completes.
import 'package:workout_tracker/core/auth_token.dart';

class PB {
  PB._();
  static final PB I = PB._();

  Future<void> clearAuthEverywhere() => AuthToken.I.clear();
}
