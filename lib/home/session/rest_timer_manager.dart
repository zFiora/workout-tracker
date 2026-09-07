import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Root-level rest timer between sets.
///
/// The source of truth is a target **timestamp** ([_endsAt]) — remaining time
/// is always computed from the wall clock, so backgrounding, locking, or
/// switching apps can never desync it (the 1s ticker only drives UI repaints;
/// if the OS pauses it, resume recomputes correctly). A single instance +
/// single internal [Timer] guarantees there's never more than one countdown.
///
/// Deliberately has **no notification dependency** — the timer is fully
/// reliable on its own; completion fires a haptic cue and a visible "done"
/// state. (Local notifications can be layered on later without changing this.)
class RestTimerManager extends ChangeNotifier {
  RestTimerManager() {
    _loadDefault();
  }

  static const _prefsKey = 'rest_default_seconds';

  Timer? _ticker;
  DateTime? _endsAt; // set while running
  Duration? _pausedRemaining; // set while paused
  bool _finished = false;
  bool _disposed = false;
  Duration _total = const Duration(seconds: 120);
  int _defaultSeconds = 120;

  int get defaultSeconds => _defaultSeconds;
  Duration get total => _total;

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

  Future<void> _loadDefault() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return; // constructor's async load may resolve post-dispose
    _defaultSeconds = prefs.getInt(_prefsKey) ?? 120;
    notifyListeners();
  }

  Future<void> setDefaultSeconds(int seconds) async {
    _defaultSeconds = seconds.clamp(10, 600);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, _defaultSeconds);
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
    notifyListeners();
  }

  void pause() {
    if (!isRunning) return;
    _pausedRemaining = remaining;
    _endsAt = null;
    _stopTicker();
    notifyListeners();
  }

  void resume() {
    final paused = _pausedRemaining;
    if (paused == null) return;
    _endsAt = DateTime.now().add(paused);
    _pausedRemaining = null;
    _ensureTicker();
    notifyListeners();
  }

  /// Skip / dismiss — clears the timer entirely.
  void skip() {
    _endsAt = null;
    _pausedRemaining = null;
    _finished = false;
    _stopTicker();
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
      notifyListeners();
    } else if (isRunning) {
      _endsAt = _endsAt!.add(Duration(seconds: seconds));
      _total += Duration(seconds: seconds);
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
    } else {
      _endsAt = DateTime.now().add(next);
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

  void _complete() {
    _endsAt = null;
    _pausedRemaining = null;
    _finished = true;
    _stopTicker();
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTicker();
    super.dispose();
  }
}
