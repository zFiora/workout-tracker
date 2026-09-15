import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Formats a rest-timer remaining duration as zero-padded `mm:ss`, clamped at
/// zero (so a negative/overdue remaining reads `00:00`). Pure — the countdown
/// is always derived from the manager's absolute end timestamp, never by
/// decrementing here.
String formatRestRemaining(Duration remaining) {
  final totalSeconds = remaining.isNegative ? 0 : remaining.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// The presentation contract the [RestTimerManager] talks to. Kept abstract so
/// the manager has no direct dependency on the notification plugin — tests
/// inject a fake, and the timer works identically with no notifier at all.
///
/// The notifier owns the decision of whether any work happens: while disabled,
/// every method is a no-op and any live notification is removed. The manager
/// only forwards timer facts (remaining is computed from its absolute end
/// timestamp), so this layer is purely a mirror.
abstract class RestTimerNotifier {
  /// Enable/disable notifications. Disabling immediately cancels any active
  /// rest notification.
  Future<void> setEnabled(bool enabled);

  /// Show/refresh the ongoing rest notification. [paused] switches the copy to
  /// the paused variant; no countdown text changes while paused.
  Future<void> showRunning({required Duration remaining, required bool paused});

  /// Replace the ongoing notification with the one-shot "rest complete" one.
  Future<void> showComplete();

  /// Remove the rest notification entirely (skip / new timer / disabled).
  Future<void> cancel();
}

/// [RestTimerNotifier] backed by `flutter_local_notifications`.
///
/// A single stable notification id guarantees only ever one rest notification
/// exists — showing again updates in place, so quick successive sets never
/// stack notifications. Channel importance is deliberately low: this mirrors a
/// rest timer, it must not buzz like an alarm on every 15s update.
class RestTimerNotificationService implements RestTimerNotifier {
  RestTimerNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int notificationId = 7001; // stable → single notification
  static const String channelId = 'rest_timer';
  static const String channelName = 'Rest timer';
  static const String channelDescription =
      'Shows the rest timer countdown and completion between sets.';

  bool _enabled = true;
  bool _initialized = false;
  bool _permissionAsked = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      // Minimal iOS settings so plugin init doesn't throw there; we do NOT
      // request any iOS permissions (Android is the target).
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: darwin),
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.low, // silent, no heads-up — not an alarm
          playSound: false,
          enableVibration: false,
        ),
      );
    } catch (e) {
      // Never let notification setup affect the workout.
      debugPrint('RestTimerNotificationService init failed: $e');
    }
  }

  /// Requests POST_NOTIFICATIONS once (Android 13+). Called lazily the first
  /// time we actually need to show something, so nothing is requested at
  /// startup. A denial just means shows silently no-op.
  Future<void> _ensurePermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('RestTimerNotificationService permission request failed: $e');
    }
  }

  AndroidNotificationDetails _androidDetails({required bool ongoing}) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true, // updates must not re-alert
      ongoing: ongoing, // running/paused = persistent; complete = dismissible
      autoCancel: !ongoing,
      showWhen: false,
      category: AndroidNotificationCategory.stopwatch,
      visibility: NotificationVisibility.public, // visible on lock screen
    );
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!enabled) {
      await cancel();
    }
  }

  @override
  Future<void> showRunning({
    required Duration remaining,
    required bool paused,
  }) async {
    if (!_enabled) return;
    await _ensureInitialized();
    await _ensurePermission();
    try {
      await _plugin.show(
        notificationId,
        paused ? 'Rest paused' : 'Rest',
        '${formatRestRemaining(remaining)} remaining',
        NotificationDetails(android: _androidDetails(ongoing: true)),
      );
    } catch (e) {
      debugPrint('RestTimerNotificationService showRunning failed: $e');
    }
  }

  @override
  Future<void> showComplete() async {
    if (!_enabled) return;
    await _ensureInitialized();
    await _ensurePermission();
    try {
      await _plugin.show(
        notificationId,
        'Rest complete',
        'Time for your next set.',
        NotificationDetails(android: _androidDetails(ongoing: false)),
      );
    } catch (e) {
      debugPrint('RestTimerNotificationService showComplete failed: $e');
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _plugin.cancel(notificationId);
    } catch (e) {
      debugPrint('RestTimerNotificationService cancel failed: $e');
    }
  }
}
