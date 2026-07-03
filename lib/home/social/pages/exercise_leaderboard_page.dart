import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/social/services/leaderboard_service.dart';

/// Per-exercise friends leaderboard.
///
/// The top three are rendered as a raised podium (2nd · 1st · 3rd) and
/// everyone else follows as a plain ranked list.
class ExerciseLeaderboardPage extends StatefulWidget {
  const ExerciseLeaderboardPage({super.key, required this.exercise});

  final ExerciseModel exercise;

  @override
  State<ExerciseLeaderboardPage> createState() =>
      _ExerciseLeaderboardPageState();
}

class _ExerciseLeaderboardPageState extends State<ExerciseLeaderboardPage> {
  final _service = LeaderboardService();
  List<ExerciseLeaderboardEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result =
        await _service.fetchExerciseFriendsRanking(widget.exercise.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case ApiSuccess(:final data):
          _entries = data;
        case ApiError(:final message):
          _error = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MyCustomeScaffoldView(
      title: widget.exercise.name,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    if (_entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.emoji_events_rounded,
            title: 'No ranking yet',
            message:
                'Add friends and log this exercise\nto see who lifts the most.',
          ),
        ],
      );
    }

    final top3 = _entries.take(3).toList();
    final rest = _entries.length > 3 ? _entries.sublist(3) : const [];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _ExerciseHeaderCard(exercise: widget.exercise),
        const SizedBox(height: 24),
        _Podium(entries: top3),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 28),
          const SectionHeader(title: 'Everyone else'),
          const SizedBox(height: 4),
          for (var i = 0; i < rest.length; i++)
            FadeRiseIn(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RankTile(entry: rest[i], rank: i + 4),
              ),
            ),
        ],
      ],
    );
  }
}

/// Small banner tying the ranking to the exercise it belongs to.
class _ExerciseHeaderCard extends StatelessWidget {
  const _ExerciseHeaderCard({required this.exercise});
  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.asset(
              exercise.workoutImage,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 56,
                height: 56,
                color: cs.surfaceContainerHigh,
                child: Icon(Icons.fitness_center_rounded,
                    color: cs.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strength ranking',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Best estimated 1RM among your friends',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The signature top-3 podium: silver (left, medium), gold (center, tall,
/// crowned), bronze (right, short).
class _Podium extends StatelessWidget {
  const _Podium({required this.entries});
  final List<ExerciseLeaderboardEntry> entries;

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    final first = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: second == null
              ? const SizedBox.shrink()
              : _PodiumSpot(
                  entry: second,
                  rank: 2,
                  color: _silver,
                  pedestalHeight: 78,
                  avatarRadius: 30,
                ),
        ),
        Expanded(
          child: first == null
              ? const SizedBox.shrink()
              : _PodiumSpot(
                  entry: first,
                  rank: 1,
                  color: _gold,
                  pedestalHeight: 110,
                  avatarRadius: 38,
                  crowned: true,
                ),
        ),
        Expanded(
          child: third == null
              ? const SizedBox.shrink()
              : _PodiumSpot(
                  entry: third,
                  rank: 3,
                  color: _bronze,
                  pedestalHeight: 56,
                  avatarRadius: 30,
                ),
        ),
      ],
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  const _PodiumSpot({
    required this.entry,
    required this.rank,
    required this.color,
    required this.pedestalHeight,
    required this.avatarRadius,
    this.crowned = false,
  });

  final ExerciseLeaderboardEntry entry;
  final int rank;
  final Color color;
  final double pedestalHeight;
  final double avatarRadius;
  final bool crowned;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FadeRiseIn(
      index: rank,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (crowned)
            Icon(Icons.emoji_events_rounded, color: color, size: 26)
          else
            const SizedBox(height: 26),
          const SizedBox(height: 6),
          // Avatar with a medal-colored ring.
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, Color.lerp(color, Colors.white, 0.5)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: cs.primaryContainer,
              backgroundImage: entry.avatarUrl != null
                  ? NetworkImage(entry.avatarUrl!)
                  : null,
              child: entry.avatarUrl == null
                  ? Text(
                      _initial(entry.displayName),
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: avatarRadius * 0.8,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.isMe ? 'You' : entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontWeight: FontWeight.w800,
              color: entry.isMe ? AppColors.volt : cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _scoreLabel(entry),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          // Pedestal.
          Container(
            height: pedestalHeight,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.30),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$rank',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initial(String name) =>
      name.isNotEmpty ? name[0].toUpperCase() : '?';
}

/// A row in the "everyone else" list.
class _RankTile extends StatelessWidget {
  const _RankTile({required this.entry, required this.rank});
  final ExerciseLeaderboardEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: entry.isMe ? AppColors.volt.withValues(alpha: 0.5) : null,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer,
            backgroundImage:
                entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.isMe ? 'You' : entry.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: entry.isMe ? AppColors.volt : cs.onSurface,
              ),
            ),
          ),
          StatPill(
            label: _scoreLabel(entry),
            icon: Icons.fitness_center_rounded,
            color: AppColors.volt,
            filled: true,
          ),
        ],
      ),
    );
  }
}

/// e.g. "100 kg × 5" — the effort behind the ranking. Falls back to the
/// estimated 1RM when the raw set isn't available.
String _scoreLabel(ExerciseLeaderboardEntry e) {
  if (e.weightKg <= 0) return '${e.oneRepMax.round()} kg';
  final w = e.weightKg == e.weightKg.roundToDouble()
      ? e.weightKg.round().toString()
      : e.weightKg.toStringAsFixed(1);
  return e.reps > 1 ? '$w kg × ${e.reps}' : '$w kg';
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.error),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
