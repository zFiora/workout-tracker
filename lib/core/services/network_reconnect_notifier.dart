import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Emits an event each time network connectivity is **regained** (an
/// offline → online transition), so callers can retry work that needs the
/// network. Purely event-driven — there is no polling.
abstract class NetworkReconnectNotifier {
  Stream<void> get onReconnect;
  Future<void> dispose();
}

/// [NetworkReconnectNotifier] backed by `connectivity_plus`.
///
/// It listens to interface changes and fires only on the offline → online edge
/// (not on every change, and not while already online), so a reconnect handler
/// runs once per reconnection rather than repeatedly. Connectivity here means
/// "an interface is up", not guaranteed internet — that's fine, because the
/// retry it triggers is itself idempotent and safely no-ops when still offline.
class ConnectivityReconnectNotifier implements NetworkReconnectNotifier {
  ConnectivityReconnectNotifier({
    Stream<List<ConnectivityResult>>? changes,
    Future<List<ConnectivityResult>> Function()? probe,
  }) {
    final source = changes ?? Connectivity().onConnectivityChanged;
    final initialProbe = probe ?? Connectivity().checkConnectivity;

    // Seed the current state so the first change is judged against reality
    // rather than an assumed default. Optimistically assume online until the
    // probe resolves (the app-launch reconcile already covers initial sync, so
    // missing the narrow probe window is harmless).
    initialProbe()
        .then((r) => _online = _isOnline(r))
        .catchError((_) => _online = true);

    // Guard setup so a missing platform plugin (e.g. in tests) can never crash
    // the owner — the notifier just never emits in that case.
    try {
      _sub = source.handleError((_) {}).listen(_onChange);
    } catch (e) {
      debugPrint('ConnectivityReconnectNotifier: listen failed: $e');
    }
  }

  final _controller = StreamController<void>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _online = true;

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  void _onChange(List<ConnectivityResult> results) {
    final online = _isOnline(results);
    final reconnected = online && !_online;
    _online = online;
    if (reconnected && !_controller.isClosed) _controller.add(null);
  }

  @override
  Stream<void> get onReconnect => _controller.stream;

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}
