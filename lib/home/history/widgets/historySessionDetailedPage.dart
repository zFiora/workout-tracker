// home/history/history_session_detail_page.dart
import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistorySessionDetailPage extends StatelessWidget {
  final WorkoutHistoryEntry entry;
  const HistorySessionDetailPage({super.key, required this.entry});

  // --------- Format helpers ---------

  String _two(int n) => n.toString().padLeft(2, '0');

  String _fmtTime(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';

  String _durationLabel(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    final s = d.inSeconds.remainder(60);
    return '${s}s';
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${wd[dt.weekday - 1]}, ${mo[dt.month - 1]} ${dt.day}';
  }

  // --------- Stats ---------

  int get _exerciseCount => entry.logs.length;

  int get _setCount => entry.logs.fold(0, (sum, log) => sum + log.sets.length);

  double get _volume => entry.logs.fold(0.0, (sum, log) {
    return sum + log.sets.fold(0.0, (s, set) => s + (set.weight * set.reps));
  });

  String _formatVolume(double v) {
    if (v >= 100) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String _setTypeShort(SetType t) {
    switch (t) {
      case SetType.work:
        return 'W';
      case SetType.warmup:
        return 'WU';
      case SetType.dropset:
        return 'DS';
    }
  }

  Color _badgeBg(ColorScheme cs, SetType t) {
    switch (t) {
      case SetType.work:
        return cs.primaryContainer;
      case SetType.warmup:
        return cs.tertiaryContainer;
      case SetType.dropset:
        return cs.secondaryContainer;
    }
  }

  Color _badgeFg(ColorScheme cs, SetType t) {
    switch (t) {
      case SetType.work:
        return cs.onPrimaryContainer;
      case SetType.warmup:
        return cs.onTertiaryContainer;
      case SetType.dropset:
        return cs.onSecondaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final day = _dayLabel(entry.endedAt);
    final timeLine =
        '${_fmtTime(entry.startedAt)} – ${_fmtTime(entry.endedAt)}';
    final duration = _durationLabel(entry.duration);

    return MyCustomeScaffoldView(
      title: entry.templateName,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _HeaderCard(
            iconPath: entry.templateIcon,
            title: entry.templateName,
            subtitle: '$day • $timeLine • $duration',
            chips: [
              _InfoChip(
                icon: Icons.list_alt_outlined,
                label: '$_exerciseCount exercises',
              ),
              _InfoChip(icon: Icons.repeat, label: '$_setCount sets'),
              _InfoChip(
                icon: Icons.scale_outlined,
                label: '${_formatVolume(_volume)} kg',
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Exercises sections
          ...entry.logs.map((log) {
            return _ExerciseCard(
              exerciseName: log.exerciseName,
              exerciseIcon: log.exerciseIcon,
              child: Column(
                children: List.generate(log.sets.length, (i) {
                  final s = log.sets[i];

                  // If you want warmups to show WU1 / WU2 instead of Set 1 / Set 2
                  final label = (s.type == SetType.warmup)
                      ? 'WU ${i + 1}'
                      : 'Set ${i + 1}';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SetRow(
                      leftLabel: label,
                      badgeText: _setTypeShort(s.type),
                      badgeBg: _badgeBg(cs, s.type),
                      badgeFg: _badgeFg(cs, s.type),
                      mainText: '${s.weight} kg × ${s.reps}',
                      subText: _fmtTime(s.timestamp),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------- UI widgets ----------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.chips,
  });

  final String iconPath;
  final String title;
  final String subtitle;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceVariant.withOpacity(0.75),
            cs.surfaceVariant.withOpacity(0.35),
          ],
        ),
        border: Border.all(color: cs.outline.withOpacity(0.22)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: cs.secondaryContainer.withOpacity(0.55),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              iconPath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.fitness_center,
                color: cs.onSecondaryContainer.withOpacity(0.85),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Text + chips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10, children: chips),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exerciseName,
    required this.exerciseIcon,
    required this.child,
  });

  final String exerciseName;
  final String exerciseIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.surface,
        border: Border.all(color: cs.outline.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: cs.secondaryContainer.withOpacity(0.6),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  exerciseIcon,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.fitness_center,
                    size: 22,
                    color: cs.onSecondaryContainer.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.leftLabel,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeFg,
    required this.mainText,
    required this.subText,
  });

  final String leftLabel;
  final String badgeText;
  final Color badgeBg;
  final Color badgeFg;
  final String mainText;
  final String subText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 66,
          child: Text(
            leftLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _Badge(text: badgeText, bg: badgeBg, fg: badgeFg),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            mainText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          subText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.65),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.18)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withOpacity(0.75)),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
