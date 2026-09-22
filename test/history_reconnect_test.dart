import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:workout_tracker/core/services/network_reconnect_notifier.dart';
import 'package:workout_tracker/core/services/reconnect_sync_binder.dart';
import 'package:workout_tracker/core/services/synced_sessions_store.dart';
import 'package:workout_tracker/home/history/repos/PREventRepository.dart';
import 'package:workout_tracker/home/history/repos/historyRepository.dart';
import 'package:workout_tracker/home/history/services/history_reconcile_cursor_store.dart';
import 'package:workout_tracker/home/history/services/historyService.dart';
import 'package:workout_tracker/home/history/services/pending_session_deletes_store.dart';
import 'package:workout_tracker/home/history/services/workout_history_reconciler.dart';
import 'package:workout_tracker/home/history/services/workout_sessions_api_service.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

// ── Fakes (no Hive/Dio) ──────────────────────────────────────────────────────

class FakeHistoryRepo implements HistoryRepository {
  final Map<int, WorkoutHistoryEntry> _map = {};
  int _next = 0;
  final _ctrl = StreamController<BoxEvent>.broadcast();

  @override
  StreamSubscription<BoxEvent> watch(void Function(BoxEvent) onEvent) =>
      _ctrl.stream.listen(onEvent);
  @override
  List<HistoryRecord> getAllRecords() => _map.entries
      .map((e) => HistoryRecord(key: e.key, entry: e.value))
      .toList();
  @override
  WorkoutHistoryEntry? get(dynamic key) => _map[key];
  @override
  Future<dynamic> add(WorkoutHistoryEntry entry) async {
    final k = _next++;
    _map[k] = entry;
    return k;
  }

  @override
  Future<void> deleteByKey(dynamic key) async => _map.remove(key);
  @override
  Future<void> clear() async => _map.clear();

  List<String> get ids => _map.values.map((e) => e.id).toList();
}

class FakePrRepo implements PrEventsRepository {
  @override
  Future<void> putEventsForHistoryKey(
      dynamic k, List<Map<String, dynamic>> e) async {}
  @override
  Future<List<Map<String, dynamic>>> loadEventsForHistoryKey(dynamic k) async =>
      const [];
  @override
  Future<void> deleteEventsForHistoryKey(dynamic k) async {}
  @override
  Future<void> clearAll() async {}
}

class FakeApi extends WorkoutSessionsApiService {
  Future<RemoteSessionPage> Function(String? cursor)? onFetch;
  Future<void> Function(String id)? onDelete;

  final List<String> deletedIds = [];
  int fetchCount = 0;

  @override
  Future<RemoteSessionPage> fetchHistoryPage({
    String? cursor,
    int limit = 200,
    bool includeDeleted = true,
  }) async {
    fetchCount++;
    return onFetch!(cursor);
  }

  @override
  Future<void> deleteSession(String id) async {
    if (onDelete != null) await onDelete!(id);
    deletedIds.add(id);
  }
}

class FakeReconnectNotifier implements NetworkReconnectNotifier {
  final _c = StreamController<void>.broadcast();
  bool disposed = false;

  void fireReconnect() {
    if (!_c.isClosed) _c.add(null);
  }

  @override
  Stream<void> get onReconnect => _c.stream;
  @override
  Future<void> dispose() async {
    disposed = true;
    await _c.close();
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

WorkoutHistoryEntry _entry(String id) => WorkoutHistoryEntry(
      id: id,
      templateId: 't',
      templateName: 'T',
      templateIcon: '',
      startedAt: DateTime(2026, 1, 1, 9),
      endedAt: DateTime(2026, 1, 1, 10),
      duration: const Duration(hours: 1),
      logs: const [],
    );

RemoteSessionChange _up(String id) =>
    RemoteSessionChange(id: id, deleted: false, entry: _entry(id));

RemoteSessionPage _page(
  List<RemoteSessionChange> changes, {
  String? nextCursor,
  required bool hasMore,
}) =>
    RemoteSessionPage(changes: changes, nextCursor: nextCursor, hasMore: hasMore);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<bool> syncedBox;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('reconnect_test');
    Hive.init(tempDir.path);
    syncedBox = await Hive.openBox<bool>('syncedSessionsBox');
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  late FakeHistoryRepo repo;
  late HistoryService service;
  late SyncedSessionsStore synced;
  late FakeApi api;
  late FakeReconnectNotifier notifier;
  const cursorStore = HistoryReconcileCursorStore();
  const pending = PendingSessionDeletesStore();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await syncedBox.clear();
    repo = FakeHistoryRepo();
    service = HistoryService(historyRepo: repo, prRepo: FakePrRepo());
    synced = SyncedSessionsStore(box: syncedBox);
    api = FakeApi();
    notifier = FakeReconnectNotifier();
  });

  WorkoutHistoryReconciler buildReconciler() => WorkoutHistoryReconciler(
        service: service,
        api: api,
        cursorStore: cursorStore,
        pendingDeletes: pending,
        synced: synced,
        userIdProvider: () => 'user1',
        pageLimit: 2,
      );

  // Mirrors HistoryViewModel's `_reconcile` wrapper wired into the binder.
  ReconnectSyncBinder bind(WorkoutHistoryReconciler r) =>
      ReconnectSyncBinder(notifier, () async {
        await r.reconcile();
      });

  test('reconnect flushes a delete that was queued while offline', () async {
    await pending.add('user1', 'x'); // queued during an offline delete
    api.onDelete = (_) async {}; // server reachable again
    api.onFetch = (_) async => _page(const [], nextCursor: null, hasMore: false);

    final binder = bind(buildReconciler());
    addTearDown(binder.dispose);

    notifier.fireReconnect();
    await pumpEventQueue();

    expect(api.deletedIds, contains('x'));
    expect(await pending.all('user1'), isEmpty);
  });

  test('reconnect retries reconciliation after an earlier failed fetch',
      () async {
    final reconciler = buildReconciler();
    final binder = bind(reconciler);
    addTearDown(binder.dispose);

    // App-launch attempt fails (offline).
    api.onFetch = (_) async => throw Exception('offline');
    await reconciler.reconcile();
    expect(repo.ids, isEmpty);

    // Connectivity returns and the server now responds.
    api.onFetch =
        (_) async => _page([_up('a'), _up('b')], nextCursor: 'c1', hasMore: false);
    notifier.fireReconnect();
    await pumpEventQueue();

    expect(repo.ids.toSet(), {'a', 'b'});
  });

  test('reconnect while reconciliation is running does not run concurrently',
      () async {
    final reconciler = buildReconciler();
    final binder = bind(reconciler);
    addTearDown(binder.dispose);

    final gate = Completer<void>();
    api.onFetch = (_) async {
      await gate.future; // hold the in-flight pass open
      return _page([_up('a')], nextCursor: 'c1', hasMore: false);
    };

    final first = reconciler.reconcile(); // starts; _running == true, blocked
    await pumpEventQueue();
    expect(api.fetchCount, 1);

    // Reconnect mid-run: the binder calls reconcile(), which must no-op.
    notifier.fireReconnect();
    await pumpEventQueue();
    expect(api.fetchCount, 1, reason: 'in-flight guard blocks a concurrent run');

    gate.complete();
    await first;
    await pumpEventQueue();

    expect(api.fetchCount, 1); // still exactly one pass
    expect(repo.ids, ['a']);
  });

  test('binder.dispose cancels the subscription and disposes the notifier',
      () async {
    var calls = 0;
    final binder = ReconnectSyncBinder(notifier, () async => calls++);

    await binder.dispose();
    expect(notifier.disposed, isTrue);

    notifier.fireReconnect(); // stream is closed / unsubscribed
    await pumpEventQueue();
    expect(calls, 0);
  });

  group('ConnectivityReconnectNotifier edge detection', () {
    test('emits only on offline → online transitions (no polling)', () async {
      final changes = StreamController<List<ConnectivityResult>>();
      final n = ConnectivityReconnectNotifier(
        changes: changes.stream,
        probe: () async => [ConnectivityResult.none], // start offline
      );
      final events = <void>[];
      n.onReconnect.listen(events.add);
      await pumpEventQueue(); // let the initial probe resolve

      changes.add([ConnectivityResult.wifi]); // offline → online
      await pumpEventQueue();
      expect(events.length, 1);

      changes.add([ConnectivityResult.mobile]); // online → online
      await pumpEventQueue();
      expect(events.length, 1, reason: 'no emit while already online');

      changes.add([ConnectivityResult.none]); // online → offline
      changes.add([ConnectivityResult.wifi]); // offline → online again
      await pumpEventQueue();
      expect(events.length, 2);

      await n.dispose();
      await changes.close();
    });
  });
}
