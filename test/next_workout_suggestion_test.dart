import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/home/history/services/next_workout_suggestion_service.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

WorkoutHistoryEntry _entry(String templateId, String name, DateTime endedAt) {
  return WorkoutHistoryEntry(
    id: '$templateId-${endedAt.millisecondsSinceEpoch}',
    templateId: templateId,
    templateName: name,
    templateIcon: '',
    startedAt: endedAt.subtract(const Duration(hours: 1)),
    endedAt: endedAt,
    duration: const Duration(hours: 1),
    logs: const [],
  );
}

/// Builds a history (unsorted on purpose — the service must sort by endedAt)
/// from a chronological list of (templateId, name) pairs, one day apart.
List<WorkoutHistoryEntry> _history(List<(String, String)> chronological) {
  final base = DateTime(2026, 1, 1, 9);
  final list = <WorkoutHistoryEntry>[];
  for (var i = 0; i < chronological.length; i++) {
    final (id, name) = chronological[i];
    list.add(_entry(id, name, base.add(Duration(days: i))));
  }
  return list.reversed.toList(); // hand it back reversed to prove sorting
}

void main() {
  const service = NextWorkoutSuggestionService();

  test('returns null with fewer than two workouts', () {
    expect(service.suggest([]), isNull);
    expect(
      service.suggest(_history([('chest', 'Chest')])),
      isNull,
    );
  });

  test('suggests the template that usually follows the last one', () {
    // Chest → Back happened twice; last workout was Chest → suggest Back.
    final history = _history([
      ('chest', 'Chest Day'),
      ('back', 'Back Day'),
      ('chest', 'Chest Day'),
      ('back', 'Back Day'),
      ('chest', 'Chest Day'),
    ]);

    final s = service.suggest(history);
    expect(s, isNotNull);
    expect(s!.suggestedTemplateId, 'back');
    expect(s.suggestedTemplateName, 'Back Day');
    expect(s.afterTemplateName, 'Chest Day');
    expect(s.timesObserved, 2);
  });

  test('picks the most frequent follower when several exist', () {
    // After chest: back twice, legs once → back wins.
    final history = _history([
      ('chest', 'Chest'),
      ('back', 'Back'),
      ('chest', 'Chest'),
      ('legs', 'Legs'),
      ('chest', 'Chest'),
      ('back', 'Back'),
      ('chest', 'Chest'),
    ]);

    final s = service.suggest(history);
    expect(s!.suggestedTemplateId, 'back');
    expect(s.timesObserved, 2);
  });

  test('ignores self-repeats — wants the next split day, not the same one', () {
    // Chest → Chest → Back. After chest the only *different* follower is back.
    final history = _history([
      ('chest', 'Chest'),
      ('chest', 'Chest'),
      ('back', 'Back'),
      ('chest', 'Chest'),
    ]);

    final s = service.suggest(history);
    expect(s, isNotNull);
    expect(s!.suggestedTemplateId, 'back');
  });

  test('returns null when the last template has no different follower', () {
    // Back has only ever been the final workout — nothing has followed it.
    final history = _history([
      ('chest', 'Chest'),
      ('back', 'Back'),
    ]);

    expect(service.suggest(history), isNull);
  });
}
