import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:workout_tracker/core/services/synced_sessions_store.dart';
import 'package:workout_tracker/home/history/repos/PREventRepository.dart';
import 'package:workout_tracker/home/history/repos/historyRepository.dart';
import 'package:workout_tracker/home/history/services/history_reconcile_cursor_store.dart';
import 'package:workout_tracker/home/history/services/historyService.dart';
import 'package:workout_tracker/home/history/services/pending_session_deletes_store.dart';
import 'package:workout_tracker/home/history/services/workout_history_reconciler.dart';
import 'package:workout_tracker/home/history/services/workout_sessions_api_service.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

// ── In-memory fakes (no Hive/Dio) ────────────────────────────────────────────

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
  final Map<dynamic, List<Map<String, dynamic>>> _m = {};
  final List<dynamic> deletedKeys = [];

  @override
  Future<void> putEventsForHistoryKey(
          dynamic k, List<Map<String, dynamic>> e) async =>
      _m[k] = e;
  @override
  Future<List<Map<String, dynamic>>> loadEventsForHistoryKey(dynamic k) async =>
      _m[k] ?? const [];
  @override
  Future<void> deleteEventsForHistoryKey(dynamic k) async {
    deletedKeys.add(k);
    _m.remove(k);
  }

  @override
  Future<void> clearAll() async => _m.clear();
}

class FakeApi extends WorkoutSessionsApiService {
  FakeApi({this.onFetch, this.onDelete});

  Future<RemoteSessionPage> Function(String? cursor)? onFetch;
  Future<void> Function(String id)? onDelete;

  final List<String?> requestedCursors = [];
  final List<String> deletedIds = [];
  int fetchCount = 0;

  @override
  Future<RemoteSessionPage> fetchHistoryPage({
    String? cursor,
    int limit = 200,
    bool includeDeleted = true,
  }) async {
    fetchCount++;
    requestedCursors.add(cursor);
    return onFetch!(cursor);
  }

  @override
  Future<void> deleteSession(String id) async {
    if (onDelete != null) await onDelete!(id);
    deletedIds.add(id);
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
RemoteSessionChange _tomb(String id) =>
    RemoteSessionChange(id: id, deleted: true);

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
    tempDir = Directory.systemTemp.createTempSync('recon_test');
    Hive.init(tempDir.path);
    syncedBox = await Hive.openBox<bool>('syncedSessionsBox');
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  late FakeHistoryRepo repo;
  late FakePrRepo pr;
  late HistoryService service;
  late SyncedSessionsStore synced;
  const cursorStore = HistoryReconcileCursorStore();
  const pending = PendingSessionDeletesStore();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await syncedBox.clear();
    repo = FakeHistoryRepo();
    pr = FakePrRepo();
    service = HistoryService(historyRepo: repo, prRepo: pr);
    synced = SyncedSessionsStore(box: syncedBox);
  });

  WorkoutHistoryReconciler build(FakeApi api, {String userId = 'user1'}) =>
      WorkoutHistoryReconciler(
        service: service,
        api: api,
        cursorStore: cursorStore,
        pendingDeletes: pending,
        synced: synced,
        userIdProvider: () => userId,
        pageLimit: 2,
      );

  test('full backfill paginates across pages until hasMore == false', () async {
    final api = FakeApi(onFetch: (cursor) async {
      if (cursor == null) {
        return _page([_up('a'), _up('b')], nextCursor: 'c1', hasMore: true);
      }
      if (cursor == 'c1') {
        return _page([_up('c'), _up('d')], nextCursor: 'c2', hasMore: false);
      }
      return _page(const [], nextCursor: cursor, hasMore: false);
    });

    await build(api).reconcile();

    expect(repo.ids.toSet(), {'a', 'b', 'c', 'd'});
    expect(api.fetchCount, 2); // stopped at hasMore == false
    expect(api.requestedCursors, [null, 'c1']);
  });

  test('cursor is persisted (high-water mark) after backfill', () async {
    final api = FakeApi(onFetch: (cursor) async {
      if (cursor == null) {
        return _page([_up('a')], nextCursor: 'c1', hasMore: true);
      }
      return _page([_up('b')], nextCursor: 'c2', hasMore: false);
    });

    await build(api).reconcile();

    expect(await cursorStore.get('user1'), 'c2');
  });

  test('incremental reconciliation resumes from the saved cursor', () async {
    await cursorStore.set('user1', 'saved');
    await service.save(_entry('a')); // already have this one locally

    final api = FakeApi(onFetch: (cursor) async {
      expect(cursor, 'saved'); // used the persisted cursor, not a full backfill
      return _page([_up('b')], nextCursor: 'saved2', hasMore: false);
    });

    await build(api).reconcile();

    expect(repo.ids.toSet(), {'a', 'b'});
    expect(await cursorStore.get('user1'), 'saved2');
  });

  test('tombstone removes the local workout (and its PR events)', () async {
    final key = await service.save(_entry('a'));

    final api = FakeApi(onFetch: (_) async {
      return _page([_tomb('a')], nextCursor: 'c1', hasMore: false);
    });

    await build(api).reconcile();

    expect(repo.ids, isNot(contains('a')));
    expect(pr.deletedKeys, contains(key)); // PR events cleaned up too
  });

  test('offline delete flushes to the server on the next reconcile', () async {
    await pending.add('user1', 'x');

    final api = FakeApi(
      onDelete: (_) async {}, // succeeds now (reconnected)
      onFetch: (_) async => _page(const [], nextCursor: null, hasMore: false),
    );

    await build(api).reconcile();

    expect(api.deletedIds, contains('x'));
    expect(await pending.all('user1'), isEmpty);
  });

  test('offline delete stays queued while the server is unreachable', () async {
    await pending.add('user1', 'x');

    final api = FakeApi(
      onDelete: (_) async => throw Exception('offline'),
      onFetch: (_) async => _page(const [], nextCursor: null, hasMore: false),
    );

    await build(api).reconcile();

    expect(await pending.all('user1'), contains('x')); // retried next time
  });

  test('a session pending deletion is never resurrected by an upsert',
      () async {
    // We deleted 'x' offline (queued); the server DELETE hasn't landed, so the
    // history feed still lists 'x' as active. It must NOT be re-added.
    await pending.add('user1', 'x');

    final api = FakeApi(
      onDelete: (_) async => throw Exception('offline'), // flush fails
      onFetch: (_) async =>
          _page([_up('x'), _up('y')], nextCursor: 'c1', hasMore: false),
    );

    await build(api).reconcile();

    expect(repo.ids, isNot(contains('x'))); // stayed deleted
    expect(repo.ids, contains('y')); // unrelated upsert still applied
  });

  test('cursors and pending deletes are account-scoped', () async {
    await cursorStore.set('userA', 'ca');
    await pending.add('userA', '1');

    expect(await cursorStore.get('userB'), isNull);
    expect(await pending.all('userB'), isEmpty);

    // A reconcile for userB must not pick up userA's cursor.
    final api = FakeApi(onFetch: (cursor) async {
      expect(cursor, isNull);
      return _page(const [], nextCursor: null, hasMore: false);
    });
    await build(api, userId: 'userB').reconcile();
    expect(api.requestedCursors, [null]);
  });

  test('duplicate reconciliation is idempotent (no dup rows)', () async {
    final api = FakeApi(onFetch: (cursor) async {
      if (cursor == null) {
        return _page([_up('a'), _up('b')], nextCursor: 'c1', hasMore: false);
      }
      // Incremental pass from 'c1' returns the same sessions again.
      return _page([_up('a'), _up('b')], nextCursor: 'c1', hasMore: false);
    });

    final r = build(api);
    await r.reconcile();
    await r.reconcile(); // second pass

    expect(repo.ids, unorderedEquals(['a', 'b'])); // still exactly two
  });

  test('concurrent reconcile calls do not overlap (in-flight guard)', () async {
    var calls = 0;
    final api = FakeApi(onFetch: (cursor) async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return _page([_up('a')], nextCursor: 'c1', hasMore: false);
    });

    final r = build(api);
    await Future.wait([r.reconcile(), r.reconcile()]);

    expect(calls, 1); // second call was a no-op while the first was running
  });

  test('empty history is a clean no-op', () async {
    final api = FakeApi(
      onFetch: (_) async => _page(const [], nextCursor: null, hasMore: false),
    );

    await build(api).reconcile();

    expect(repo.ids, isEmpty);
    expect(await cursorStore.get('user1'), isNull); // unchanged
  });

  test('a failed fetch is swallowed and leaves state intact', () async {
    await cursorStore.set('user1', 'keep');
    await service.save(_entry('a'));

    final api = FakeApi(onFetch: (_) async => throw Exception('network down'));

    await build(api).reconcile(); // must not throw

    expect(repo.ids, ['a']); // cache untouched
    expect(await cursorStore.get('user1'), 'keep'); // cursor preserved
  });

  test('pagination stops exactly when hasMore is false', () async {
    final api = FakeApi(onFetch: (cursor) async {
      if (cursor == null) {
        return _page([_up('a')], nextCursor: 'c1', hasMore: true);
      }
      return _page([_up('b')], nextCursor: 'c2', hasMore: false);
    });

    await build(api).reconcile();

    expect(api.fetchCount, 2);
    expect(repo.ids.toSet(), {'a', 'b'});
  });

  test('an invalid saved cursor resets to a full backfill', () async {
    await cursorStore.set('user1', 'stale');

    final api = FakeApi(onFetch: (cursor) async {
      if (cursor == 'stale') {
        throw CursorInvalidException('cursor expired');
      }
      // Restart from scratch (cursor == null).
      return _page([_up('a'), _up('b')], nextCursor: 'fresh', hasMore: false);
    });

    await build(api).reconcile();

    expect(api.requestedCursors, ['stale', null]); // reset happened
    expect(repo.ids.toSet(), {'a', 'b'});
    expect(await cursorStore.get('user1'), 'fresh');
  });

  test('no reconciliation when signed out (null userId)', () async {
    final api = FakeApi(onFetch: (_) async => _page(const [], hasMore: false));
    final r = WorkoutHistoryReconciler(
      service: service,
      api: api,
      cursorStore: cursorStore,
      pendingDeletes: pending,
      synced: synced,
      userIdProvider: () => null,
    );

    await r.reconcile();

    expect(api.fetchCount, 0);
  });
}
