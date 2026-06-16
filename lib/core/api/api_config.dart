/// Central place for all API / network configuration.
///
/// When connecting a real backend, change [baseUrl] (or supply it via
/// `--dart-define=API_BASE_URL=https://...` at build time so the value
/// differs between dev / staging / prod without touching source code).
class ApiConfig {
  ApiConfig._();

  /// .NET API server URL.
  /// Android emulator localhost  → 10.0.2.2
  /// iOS simulator localhost     → 127.0.0.1
  /// Real device on LAN          → your machine's LAN IP
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5289',
  );

  /// Seconds before a network request is considered timed out.
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── API route prefixes ───────────────────────────────────────────────────
  static const String colUsers       = 'users';
  static const String colFriends     = 'friendships';
  static const String colWorkouts    = 'workouts';
  static const String colTemplates   = 'templates';
  static const String colLeaderboard = 'leaderboard';
  static const String colPrEvents    = 'pr_events';

  // ── Hive box names ───────────────────────────────────────────────────────
  static const String boxHistory      = 'historyBox';
  static const String boxTemplates    = 'templatesBox';
  static const String boxMeasurements = 'measurementsBox';
  static const String boxPrEvents     = 'prEventsBox';
  static const String boxExNotes      = 'exerciseNotesBox';
}
