/// App-wide weight unit preference.
///
/// **Canonical storage is always kilograms.** Every weight persisted anywhere
/// (sets, PRs, bodyweight, measurements) is kg. Conversion happens only at the
/// presentation/input boundary via [display] / [toKg], so switching kg↔lb
/// never mutates or rounds stored data.
enum WeightUnit { kg, lb }

const double _kgPerLb = 0.45359237;

extension WeightUnitX on WeightUnit {
  String get label => this == WeightUnit.kg ? 'kg' : 'lb';

  /// Convert a canonical kg value into this unit for display/editing.
  double fromKg(double kg) => this == WeightUnit.kg ? kg : kg / _kgPerLb;

  /// Convert a user-entered value in this unit back to canonical kg.
  /// Full precision — never round on the way into storage.
  double toKg(double value) => this == WeightUnit.kg ? value : value * _kgPerLb;

  /// Display string for a canonical kg value, without the unit suffix.
  /// One decimal, trailing `.0` trimmed (e.g. `100`, `102.5`).
  String format(double kg) {
    final v = fromKg(kg);
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  /// Display string with the unit suffix (e.g. `102.5 kg`, `225 lb`).
  String formatWithUnit(double kg) => '${format(kg)} $label';

  static WeightUnit fromName(String? name) =>
      name == 'lb' ? WeightUnit.lb : WeightUnit.kg;
}
