import 'package:workout_tracker/home/session/models/sessionModels.dart';

/// A data-driven "what to train next" hint, derived from the order the user
/// has historically done their workouts in.
class NextWorkoutSuggestion {
  const NextWorkoutSuggestion({
    required this.suggestedTemplateId,
    required this.suggestedTemplateName,
    required this.afterTemplateName,
    required this.timesObserved,
  });

  /// Template the user tends to do next.
  final String suggestedTemplateId;

  /// Its name as last seen in history (the page re-resolves against the live
  /// template for the current name/exercises).
  final String suggestedTemplateName;

  /// The most-recently-completed workout this suggestion follows on from.
  final String afterTemplateName;

  /// How many times this "after X → do Y" transition has occurred — drives
  /// the confidence wording ("usually" vs "last time").
  final int timesObserved;
}

/// Suggests the next workout by learning the user's split from history: for
/// the template they most recently trained, which *different* template has
/// most often followed it before.
///
/// Example: history shows Chest → Back several times; the last workout was
/// Chest → suggest starting a Back day. Falls back to null (caller then
/// offers a plain "repeat last workout") when there's no repeatable pattern
/// yet — a brand-new template, a first-ever session, or a last workout that's
/// only ever been done at the very end.
class NextWorkoutSuggestionService {
  const NextWorkoutSuggestionService();

  NextWorkoutSuggestion? suggest(List<WorkoutHistoryEntry> history) {
    final entries = history.where((e) => e.templateId.isNotEmpty).toList()
      ..sort((a, b) => a.endedAt.compareTo(b.endedAt));
    if (entries.length < 2) return null;

    final lastId = entries.last.templateId;

    final followerCount = <String, int>{};
    final followerLastAt = <String, DateTime>{};
    final nameById = <String, String>{};

    // Walk every consecutive (from → to) pair; only tally the ones that
    // follow the template the user just did, and ignore self-repeats since
    // the goal is to suggest the *next* day in the split.
    for (var i = 0; i < entries.length - 1; i++) {
      final from = entries[i].templateId;
      final to = entries[i + 1].templateId;
      nameById[to] = entries[i + 1].templateName;

      if (from != lastId || to == from) continue;

      followerCount[to] = (followerCount[to] ?? 0) + 1;
      final at = entries[i + 1].endedAt;
      final prev = followerLastAt[to];
      if (prev == null || at.isAfter(prev)) followerLastAt[to] = at;
    }

    if (followerCount.isEmpty) return null;

    // Most frequent follower wins; ties break toward the more recently done.
    final ranked = followerCount.keys.toList()
      ..sort((a, b) {
        final byCount = followerCount[b]!.compareTo(followerCount[a]!);
        if (byCount != 0) return byCount;
        return followerLastAt[b]!.compareTo(followerLastAt[a]!);
      });
    final best = ranked.first;

    return NextWorkoutSuggestion(
      suggestedTemplateId: best,
      suggestedTemplateName: nameById[best] ?? '',
      afterTemplateName: entries.last.templateName,
      timesObserved: followerCount[best]!,
    );
  }
}
