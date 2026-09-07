import 'package:hive/hive.dart';

part 'sex.g.dart';

/// Explicit sex options, used for BMR calculations (`MacroProfile`) and
/// sex-based theming (`app_theme.dart`). Lives in `common` rather than a
/// single feature module since both depend on it — a single shared field,
/// not duplicated per-feature.
///
/// `unspecified` is the default for anyone who hasn't set this yet — it is
/// never guessed from another field (e.g. the legacy `isMale` BMR flag).
@HiveType(typeId: 33)
enum Sex {
  @HiveField(0)
  unspecified,
  @HiveField(1)
  male,
  @HiveField(2)
  female,
}
