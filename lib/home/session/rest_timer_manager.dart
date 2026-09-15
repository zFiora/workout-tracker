import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rest_timer_notification_service.dart';

/// Root-level rest timer between sets.
///
/// The source of truth is a target **timestamp** ([_endsAt]) — remaining time
/// is always computed from the wall clock, so backgrounding, locking, or
/// switching apps can never desync it (the 1s ticker only drives UI repaints;
/// if the OS pauses it, resume recomputes correctly). A single instance +
/// single internal [Timer] guarantees there's never more than one countdown.
///
/// An **optional** [RestTimerNotifier] mirrors the timer to an Android
/// notification. It is purely presentation: the timer is fully functional with
/// it null, and it never drives timer state. Remaining time shown in the
/// notification is always recomputed from [_endsAt] (never decremented), so a
/// delayed background update self-corrects. A separate ~15s ticker refreshes
/// the notification, independent of the accurate 1s UI ticker.
class RestTimerManager extends ChangeNotifier {
  RestTimerManager([RestTimerNotifier? notifier]) : _notifier = notifier {
    _loadPrefs();
  }

  static const _prefsKey = 'rest_default_seconds';
  static const _notificationsPrefsKey = 'rest_timer_notifications_enabled';

  final RestTimerNotifier? _notifier;

  Timer? _ticker;
  Timer? _notifyTicker; // ~15s notification refresh; independent of _ticker
  DateTime? _endsAt; // set while running
  Duration? _pausedRemaining; // set while paused
  bool _finished = false;
  bool _disposed = false;
  Duration _total = const Duration(seconds: 120);
  int _defaultSeconds = 120;
  bool _notificationsEnabled = true;

  int get defaultSeconds => _defaultSeconds;
  Duration get total => _total;
  bool get notificationsEnabled => _notificationsEnabled;

  bool get isRunning => _endsAt != null;
  bool get isPaused => _pausedRemaining != null;
  bool get isFinished => _finished;
  bool get isActive => isRunning || isPaused || _finished;

  Duration get remaining {
    if (_finished) return Duration.zero;
    if (_pausedRemaining != null) return _pausedRemaining!;
    final ends = _endsAt;
    if (ends == null) return Duration.zero;
    final r = ends.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  /// 0.0 → 1.0 elapsed fraction, for a progress ring.
  double get progress {
    if (_total.inMilliseconds == 0) return 0;
    final done = _total - remaining;
    return (done.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return; // constructor's async load may resolve post-dispose
    _defaultSeconds = prefs.getInt(_prefsKey) ?? 120;
    // Notifications are enabled by default for new AND existing users.
    _notificationsEnabled = prefs.getBool(_notificationsPrefsKey) ?? true;
    _notifier?.setEnabled(_notificationsEnabled);
    notifyListeners();
  }

  Future<void> setDefaultSeconds(int seconds) async {
    _defaultSeconds = seconds.clamp(10, 600);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, _defaultSeconds);
  }

  /// Toggles rest-timer notifications. Purely a presentation concern: it never
  /// starts, stops, pauses, skips, re-times, or otherwise touches the timer.
  ///
  /// Turning OFF immediately removes any active notification and stops refresh
  /// scheduling; the timer keeps running untouched. Turning ON while a rest is
  /// active immediately mirrors the current remaining time (from [_endsAt]),
  /// without restarting anything.
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();

    await _notifier?.setEnabled(enabled);

    if (enabled) {
      if (_finished) {
        await _notifier?.showComplete();
      } else if (isRunning) {
        _startNotifyLoop(); // pushes current remaining immediately
      } else if (isPaused) {
        await _notifier?.showRunning(remaining: remaining, paused: true);
      }
    } else {
      // setEnabled(false) already cancelled the notification; stop refreshing.
      _stopNotifyLoop();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsPrefsKey, enabled);
  }

  /// Starts (or restarts) the timer. Any existing countdown is replaced, so
  /// completing sets in quick succession never stacks timers.
  void start([Duration? duration]) {
    final d = duration ?? Duration(seconds: _defaultSeconds);
    _total = d;
    _pausedRemaining = null;
    _finished = false;
    _endsAt = DateTime.now().add(d);
    _ensureTicker();
    _startNotifyLoop(); // replaces any old notification; pushes immediately
    notifyListeners();
  }

  void pause() {
    if (!isRunning) return;
    _pausedRemaining = remaining;
    _endsAt = null;
    _stopTicker();
    _stopNotifyLoop(); // no countdown while paused
    if (_notificationsEnabled) {
      _notifier?.showRunning(remaining: _pausedRemaining!, paused: true);
    }
    notifyListeners();
  }

  void resume() {
    final paused = _pausedRemaining;
    if (paused == null) return;
    _endsAt = DateTime.now().add(paused);
    _pausedRemaining = null;
    _ensureTicker();
    _startNotifyLoop(); // resume 15s cycle + immediate refresh
    notifyListeners();
  }

  /// Skip / dismiss — clears the timer entirely.
  void skip() {
    _endsAt = null;
    _pausedRemaining = null;
    _finished = false;
    _stopTicker();
    _stopNotifyLoop();
    _notifier?.cancel(); // remove the notification; no "Rest complete"
    notifyListeners();
  }

  void addSeconds(int seconds) {
    if (_finished) {
      // Extending a finished rest just starts a fresh short rest.
      start(Duration(seconds: seconds.clamp(0, 600)));
      return;
    }
    if (isPaused) {
      _pausedRemaining = _pausedRemaining! + Duration(seconds: seconds);
      _total += Duration(seconds: seconds);
      if (_notificationsEnabled) {
        _notifier?.showRunning(remaining: _pausedRemaining!, paused: true);
      }
      notifyListeners();
    } else if (isRunning) {
      _endsAt = _endsAt!.add(Duration(seconds: seconds));
      _total += Duration(seconds: seconds);
      _pushRunningNotification(); // immediate — never wait up to 15s
      notifyListeners();
    }
  }

  void subtractSeconds(int seconds) {
    if (!isActive || _finished) return;
    final current = remaining;
    final next = current - Duration(seconds: seconds);
    if (next <= Duration.zero) {
      _complete();
      return;
    }
    if (isPaused) {
      _pausedRemaining = next;
      if (_notificationsEnabled) {
        _notifier?.showRunning(remaining: next, paused: true);
      }
    } else {
      _endsAt = DateTime.now().add(next);
      _pushRunningNotification();
    }
    notifyListeners();
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (isRunning && remaining <= Duration.zero) {
        _complete();
      } else {
        notifyListeners();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  // ── notification refresh loop (presentation only) ───────────────────────

  void _startNotifyLoop() {
    _stopNotifyLoop();
    if (!_notificationsEnabled || _notifier == null) return;
    _pushRunningNotification(); // immediate first paint — no 15s wait
    _notifyTicker = Timer.periodic(const Duration(seconds: 15), (_) {
      // The absolute end timestamp is the source of truth: if we've crossed
      // zero, the 1s ticker fires _complete(); otherwise refresh the mirror.
      if (isRunning) _pushRunningNotification();
    });
  }

  void _stopNotifyLoop() {
    _notifyTicker?.cancel();
    _notifyTicker = null;
  }

  void _pushRunningNotification() {
    if (!_notificationsEnabled) return;
    _notifier?.showRunning(remaining: remaining, paused: false);
  }

  void _complete() {
    _endsAt = null;
    _pausedRemaining = null;
    _finished = true;
    _stopTicker();
    _stopNotifyLoop();
    HapticFeedback.mediumImpact();
    if (_notificationsEnabled) {
      _notifier?.showComplete();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTicker();
    _stopNotifyLoop();
    super.dispose();
  }
}
