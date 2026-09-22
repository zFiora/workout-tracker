import 'dart:async';

import 'package:workout_tracker/core/services/network_reconnect_notifier.dart';

/// Wires a [NetworkReconnectNotifier] to a callback, invoking it on every
/// reconnection. Keeps the subscription lifecycle in one small, testable place
/// so owners (e.g. `HistoryViewModel`) just provide the "what to run" callback.
///
/// The callback is expected to be idempotent and self-guarding against
/// concurrent runs (the reconciler already is), so this binder deliberately
/// does not add its own de-duplication.
class ReconnectSyncBinder {
  ReconnectSyncBinder(this._notifier, this._onReconnect) {
    _sub = _notifier.onReconnect.listen((_) => _onReconnect());
  }

  final NetworkReconnectNotifier _notifier;
  final Future<void> Function() _onReconnect;
  StreamSubscription<void>? _sub;

  Future<void> dispose() async {
    await _sub?.cancel();
    await _notifier.dispose();
  }
}
