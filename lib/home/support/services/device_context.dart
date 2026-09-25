import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:package_info_plus/package_info_plus.dart';

/// Best-effort app/device context attached to a bug report. The app version
/// comes from the platform build (pubspec `version:` → versionName/versionCode,
/// CFBundleShortVersionString/CFBundleVersion) via `package_info_plus`; the
/// rest is sourced from dart:io `Platform`.
abstract final class DeviceContext {
  static String? _appVersion;

  /// `version+build` (e.g. "1.0.0+1"), the same string shown in the
  /// Account page footer. Null until [init] has completed, or if the platform
  /// lookup failed — callers treat it as optional.
  static String? get appVersion => _appVersion;

  /// Reads the build's version once. Called from `main()` before `runApp`
  /// so [appVersion] is available synchronously everywhere afterwards.
  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = formatVersion(info.version, info.buildNumber);
    } catch (_) {
      _appVersion = null;
    }
  }

  /// Backend column is capped at 50 chars (see BugReport.AppVersion).
  @visibleForTesting
  static String? formatVersion(String version, String buildNumber) {
    final v = version.trim();
    final b = buildNumber.trim();
    if (v.isEmpty) return null;
    final combined = b.isEmpty ? v : '$v+$b';
    return combined.length > 50 ? combined.substring(0, 50) : combined;
  }

  @visibleForTesting
  static void resetForTesting() => _appVersion = null;

  static String get platform {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isWindows) return 'windows';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isLinux) return 'linux';
    } catch (_) {
      // Platform.* throws on unsupported embedders; fall through.
    }
    return 'unknown';
  }

  /// OS name + version (e.g. "android 14"). Not as detailed as a
  /// device-info plugin (no manufacturer/model), but requires zero new
  /// dependencies for an optional diagnostic field.
  static String? get deviceInfo {
    if (kIsWeb) return null;
    try {
      final combined = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'
          .trim();
      if (combined.isEmpty) return null;
      // Backend column is capped at 200 chars (see BugReport.DeviceInfo).
      return combined.length > 200 ? combined.substring(0, 200) : combined;
    } catch (_) {
      return null;
    }
  }
}
