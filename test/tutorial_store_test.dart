import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_tracker/common/tutorial/tutorial_store.dart';

void main() {
  const store = TutorialStore();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('storage key format is tutorial_<id>_version', () {
    expect(TutorialStore.storageKey('workout'), 'tutorial_workout_version');
  });

  test('an unseen tutorial should show', () async {
    expect(await store.shouldShow('templates', 1), isTrue);
    expect(await store.seenVersion('templates'), 0);
  });

  test('after markSeen at v1, the same version no longer shows', () async {
    await store.markSeen('templates', 1);
    expect(await store.shouldShow('templates', 1), isFalse);
    expect(await store.seenVersion('templates'), 1);
  });

  test('bumping a tutorial version re-shows only that tutorial', () async {
    await store.markSeen('templates', 1);
    await store.markSeen('workout', 1);

    // Version 2 of templates is "new" → shows again...
    expect(await store.shouldShow('templates', 2), isTrue);
    // ...while workout v1 stays seen (independent versioning).
    expect(await store.shouldShow('workout', 1), isFalse);
  });

  test('markSeen is monotonic — it never lowers a stored version', () async {
    await store.markSeen('templates', 3);
    await store.markSeen('templates', 1); // must be ignored
    expect(await store.seenVersion('templates'), 3);
    expect(await store.shouldShow('templates', 2), isFalse);
  });

  test('tutorials are tracked independently by id', () async {
    await store.markSeen('templates', 1);
    expect(await store.shouldShow('history', 1), isTrue);
    expect(await store.shouldShow('workout', 1), isTrue);
  });

  test('reset clears a tutorial so it shows again', () async {
    await store.markSeen('templates', 1);
    await store.reset('templates');
    expect(await store.shouldShow('templates', 1), isTrue);
  });
}
