// Persisted workout recaps: serialization, the local store, progress-photo
// files, backward compatibility, and proof nothing new reaches the sync
// payload or the network layer.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/recap/progress_photo_store.dart';
import 'package:workout_tracker/home/session/recap/workout_recap.dart';
import 'package:workout_tracker/home/session/recap/workout_recap_service.dart';
import 'package:workout_tracker/home/session/recap/workout_recap_store.dart';
import 'package:workout_tracker/home/session/services/muscle_summary_service.dart';

final _t = DateTime(2026, 9, 25, 18, 30);

const _summary = MuscleSummary(
  primary: {Muscle.chest, Muscle.triceps},
  secondary: {Muscle.frontDelts},
  setsPerMuscle: {Muscle.chest: 6, Muscle.triceps: 4, Muscle.frontDelts: 6},
  unrecognizedExercises: ['Treadmill'],
);

WorkoutHistoryEntry _entry({String id = 'w1', List<ExerciseLog>? logs}) =>
    WorkoutHistoryEntry(
      id: id,
      templateId: 't',
      templateName: 'Push Day',
      templateIcon: '',
      startedAt: _t,
      endedAt: _t.add(const Duration(hours: 1)),
      duration: const Duration(hours: 1),
      logs:
          logs ??
          [
            ExerciseLog(
              exerciseId: 3, // Bench Press
              exerciseName: 'Bench Press (Barbell)',
              exerciseIcon: '',
              sets: [PerformedSet(weight: 80, reps: 8, timestamp: _t)],
            ),
          ],
    );

void expectSameSummary(MuscleSummary a, MuscleSummary b) {
  expect(a.primary, b.primary);
  expect(a.secondary, b.secondary);
  expect(a.setsPerMuscle, b.setsPerMuscle);
  expect(a.unrecognizedExercises, b.unrecognizedExercises);
}

void main() {
  group('MuscleSummary serialization', () {
    test('round-trips through JSON', () {
      final json =
          jsonDecode(jsonEncode(_summary.toJson())) as Map<String, dynamic>;
      expectSameSummary(MuscleSummary.fromJson(json), _summary);
    });

    test('stores muscles by name, not enum index', () {
      final json = _summary.toJson();
      expect(json['primary'], ['chest', 'triceps']);
      expect(json['secondary'], ['frontDelts']);
      expect(
        (json['setsPerMuscle'] as Map).keys,
        containsAll(['chest', 'triceps']),
      );
    });

    test('skips muscle names this build does not know', () {
      final s = MuscleSummary.fromJson({
        'primary': ['chest', 'neck'],
        'secondary': ['forearms', 'tibialis'],
        'setsPerMuscle': {'chest': 3, 'neck': 2},
      });
      expect(s.primary, {Muscle.chest});
      expect(s.secondary, {Muscle.forearms});
      expect(s.setsPerMuscle, {Muscle.chest: 3});
      expect(s.unrecognizedExercises, isEmpty);
    });

    test('re-asserts primary-over-secondary on read', () {
      final s = MuscleSummary.fromJson({
        'primary': ['chest'],
        'secondary': ['chest', 'triceps'],
      });
      expect(s.secondary, {Muscle.triceps});
    });
  });

  group('WorkoutRecap serialization', () {
    test('round-trips, including the photo file name', () {
      final recap = WorkoutRecap(
        workoutId: 'w1',
        summary: _summary,
        prCount: 2,
        createdAt: _t,
        photoFileName: 'abc.jpg',
      );
      final back = WorkoutRecap.fromJson(
        jsonDecode(jsonEncode(recap.toJson())) as Map<String, dynamic>,
      );
      expect(back.workoutId, 'w1');
      expect(back.prCount, 2);
      expect(back.createdAt, _t);
      expect(back.photoFileName, 'abc.jpg');
      expectSameSummary(back.summary, _summary);
      expect(recap.toJson()['version'], WorkoutRecap.currentVersion);
    });

    test('omits the photo key when there is no photo', () {
      final json = WorkoutRecap(
        workoutId: 'w1',
        summary: _summary,
        prCount: 0,
        createdAt: _t,
      ).toJson();
      expect(json.containsKey('photoFileName'), isFalse);
    });

    test('reads a minimal/partial record without throwing', () {
      final r = WorkoutRecap.fromJson({'workoutId': 'w1'});
      expect(r.prCount, 0);
      expect(r.hasPhoto, isFalse);
      expect(r.summary.hasMuscles, isFalse);
    });
  });

  group('stores', () {
    late Directory tmp;
    late Box<String> box;
    late ProgressPhotoStore photos;
    late WorkoutRecapStore store;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('recap_test');
      Hive.init('${tmp.path}/hive');
      box = await Hive.openBox<String>(WorkoutRecapStore.boxName);
      photos = ProgressPhotoStore(baseDir: () async => tmp);
      store = WorkoutRecapStore(box: box, photos: photos);
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await Hive.close();
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    Future<String> sourcePhoto(String name) async {
      final f = File('${tmp.path}/$name');
      await f.writeAsBytes([1, 2, 3, 4]);
      return f.path;
    }

    test('historical summary survives save/load exactly as saved', () async {
      // The stored summary deliberately differs from what today's catalog
      // would compute for this workout (Bench → chest | front delts, triceps).
      const frozen = MuscleSummary(
        primary: {Muscle.calves},
        secondary: {},
        setsPerMuscle: {Muscle.calves: 1},
        unrecognizedExercises: [],
      );
      await store.put(
        WorkoutRecap(
          workoutId: 'w1',
          summary: frozen,
          prCount: 1,
          createdAt: _t,
        ),
      );

      // Simulate an app restart: reopen the box from disk.
      await box.close();
      box = await Hive.openBox<String>(WorkoutRecapStore.boxName);
      final loaded = WorkoutRecapStore(box: box, photos: photos).get('w1')!;

      expectSameSummary(loaded.summary, frozen);
      expect(computeMuscleSummary(_entry()).primary, isNot(frozen.primary));
    });

    test('old workouts without a recap read as null', () {
      expect(store.get('never-saved'), isNull);
      expect(store.get(''), isNull);
    });

    test(
      'an unreadable stored value reads as null instead of throwing',
      () async {
        await box.put('w1', '{not json');
        final logged = <String>[];
        final original = debugPrint;
        debugPrint = (String? m, {int? wrapWidth}) => logged.add(m ?? '');
        try {
          expect(store.get('w1'), isNull);
        } finally {
          debugPrint = original;
        }
        expect(logged, [contains('unreadable recap for w1')]);
      },
    );

    test('get returns null when the box is not open (no crash)', () async {
      final unopened = WorkoutRecapStore(photos: photos);
      await Hive.close();
      expect(unopened.get('w1'), isNull);
      box = await Hive.openBox<String>(
        WorkoutRecapStore.boxName,
      ); // for tearDown
    });

    test(
      'photos are copied locally and referenced by file name only',
      () async {
        final name = await photos.persist(await sourcePhoto('picked.JPG'));
        expect(name, isNot(contains('/')));
        expect(name, isNot(contains(r'\')));
        expect(name, endsWith('.jpg'));
        final file = await photos.resolve(name);
        expect(file, isNotNull);
        expect(file!.path, contains(ProgressPhotoStore.folderName));
        expect(await file.readAsBytes(), [1, 2, 3, 4]);
      },
    );

    test('unsafe photo names are refused', () async {
      expect(await photos.resolve('../secrets.txt'), isNull);
      expect(await photos.resolve('a/b.jpg'), isNull);
      expect(await photos.resolve(''), isNull);
    });

    test(
      'setPhoto attaches, replaces (deleting the old file) and removes',
      () async {
        var recap = WorkoutRecap(
          workoutId: 'w1',
          summary: _summary,
          prCount: 0,
          createdAt: _t,
        );
        await store.put(recap);

        final first = await photos.persist(await sourcePhoto('a.jpg'));
        recap = await store.setPhoto(recap, first);
        expect(store.get('w1')!.photoFileName, first);

        final second = await photos.persist(await sourcePhoto('b.png'));
        recap = await store.setPhoto(recap, second);
        expect(store.get('w1')!.photoFileName, second);
        expect(
          await photos.resolve(first),
          isNull,
          reason: 'replaced photo deleted',
        );

        recap = await store.setPhoto(recap, null);
        expect(store.get('w1')!.hasPhoto, isFalse);
        expect(await photos.resolve(second), isNull);
        // The summary itself is untouched by photo changes.
        expectSameSummary(store.get('w1')!.summary, _summary);
      },
    );

    test(
      'pruneOrphans removes recaps and photos of deleted workouts only',
      () async {
        final photo = await photos.persist(await sourcePhoto('gone.jpg'));
        await store.put(
          WorkoutRecap(
            workoutId: 'kept',
            summary: _summary,
            prCount: 0,
            createdAt: _t,
          ),
        );
        await store.put(
          WorkoutRecap(
            workoutId: 'deleted',
            summary: _summary,
            prCount: 0,
            createdAt: _t,
            photoFileName: photo,
          ),
        );

        final removed = await store.pruneOrphans({'kept'});

        expect(removed, 1);
        expect(store.get('kept'), isNotNull);
        expect(store.get('deleted'), isNull);
        expect(await photos.resolve(photo), isNull);
      },
    );

    test('deleteAll wipes every progress photo (account switch)', () async {
      final a = await photos.persist(await sourcePhoto('1.jpg'));
      final b = await photos.persist(await sourcePhoto('2.jpg'));
      await photos.deleteAll();
      expect(await photos.resolve(a), isNull);
      expect(await photos.resolve(b), isNull);
    });

    test(
      'createRecapForSavedWorkout freezes and persists the summary',
      () async {
        final recap = await createRecapForSavedWorkout(
          _entry(),
          prCount: 3,
          store: store,
          now: () => _t,
        );
        expect(recap, isNotNull);
        final stored = store.get('w1')!;
        expect(stored.prCount, 3);
        expect(stored.summary.primary, {Muscle.chest});
        expect(stored.summary.secondary, {Muscle.frontDelts, Muscle.triceps});
      },
    );

    test(
      'createRecapForSavedWorkout never throws when the summary fails',
      () async {
        final logged = <String>[];
        final original = debugPrint;
        debugPrint = (String? m, {int? wrapWidth}) => logged.add(m ?? '');
        final WorkoutRecap? recap;
        try {
          recap = await createRecapForSavedWorkout(
            _entry(),
            prCount: 0,
            store: store,
            computeSummary: (_) => throw StateError('boom'),
          );
        } finally {
          debugPrint = original;
        }
        expect(recap, isNull);
        expect(logged, [contains('summary failed for w1')]);
        expect(store.get('w1'), isNull);
      },
    );

    test(
      'createRecapForSavedWorkout still returns the recap if storing fails',
      () async {
        await box.close(); // writes will now throw
        final logged = <String>[];
        final original = debugPrint;
        debugPrint = (String? m, {int? wrapWidth}) => logged.add(m ?? '');
        final WorkoutRecap? recap;
        try {
          recap = await createRecapForSavedWorkout(
            _entry(),
            prCount: 0,
            store: store,
          );
        } finally {
          debugPrint = original;
        }
        expect(recap, isNotNull);
        expect(logged, [contains('could not persist recap for w1')]);
        box = await Hive.openBox<String>(
          WorkoutRecapStore.boxName,
        ); // for tearDown
      },
    );
  });

  group('sync payload and network isolation', () {
    test('WorkoutHistoryEntry.toJson (the sync payload) is unchanged', () {
      expect(_entry().toJson().keys.toSet(), {
        'id',
        'templateId',
        'templateName',
        'templateIcon',
        'startedAt',
        'endedAt',
        'durationMs',
        'logs',
      });
    });

    test('recap, photo and export code never imports the network layer', () {
      final files = [
        ...Directory('lib/home/session/recap').listSync().whereType<File>(),
        File('lib/home/session/pages/workout_summary_page.dart'),
        File('lib/home/history/widgets/history_recap_card.dart'),
        File('lib/common/widgets/muscle_map/muscle_overlay.dart'),
      ];
      expect(files, isNotEmpty);
      final forbidden = RegExp(
        r'api_client|package:dio|package:http/|ApiClient|HttpClient',
      );
      for (final f in files) {
        expect(
          forbidden.hasMatch(f.readAsStringSync()),
          isFalse,
          reason: f.path,
        );
      }
    });
  });
}
