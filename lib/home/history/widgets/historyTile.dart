import 'package:flutter/material.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
  });

  final WorkoutHistoryEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  // --------- Formatting ---------

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatTime(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';

  String _formatDayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];

    final w = wd[dt.weekday - 1];
    final m = mo[dt.month - 1];
    return '$w, $m ${dt.day}';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    final s = d.inSeconds.remainder(60);
    return '${s}s';
  }

  String _formatVolume(double v) {
    // Keep it simple: show 0 decimals if big enough, 1 decimal if small
    if (v >= 100) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  // --------- Stats ---------

  int get _exerciseCount => entry.logs.length;

  int get _setCount =>
      entry.logs.fold(0, (sum, log) => sum + log.sets.length);

  double get _volume =>
      entry.logs.fold(0.0, (sum, log) {
        return sum +
            log.sets.fold(0.0, (s, set) => s + (set.weight * set.reps));
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final dayLabel = _formatDayLabel(entry.endedAt);
    final timeLabel =
        '${_formatTime(entry.startedAt)} – ${_formatTime(entry.endedAt)}';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surfaceVariant.withOpacity(0.70),
              cs.surfaceVariant.withOpacity(0.35),
            ],
          ),
          border: Border.all(
            color: cs.outline.withOpacity(0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Leading icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: cs.secondaryContainer.withOpacity(0.6),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  entry.templateIcon,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.fitness_center,
                    color: cs.onSecondaryContainer.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + day label
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.templateName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          icon: Icons.calendar_today_outlined,
                          label: dayLabel,
                          background: cs.tertiaryContainer,
                          foreground: cs.onTertiaryContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Time range (sub)
                    Text(
                      timeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Stats pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(
                          icon: Icons.timer_outlined,
                          label: _formatDuration(entry.duration),
                          background: cs.primaryContainer,
                          foreground: cs.onPrimaryContainer,
                        ),
                        _Pill(
                          icon: Icons.list_alt_outlined,
                          label: '$_exerciseCount ex',
                          background: cs.secondaryContainer,
                          foreground: cs.onSecondaryContainer,
                        ),
                        _Pill(
                          icon: Icons.repeat,
                          label: '$_setCount sets',
                          background: cs.secondaryContainer,
                          foreground: cs.onSecondaryContainer,
                        ),
                        _Pill(
                          icon: Icons.scale_outlined,
                          label: '${_formatVolume(_volume)} kg',
                          background: cs.surface,
                          foreground: cs.onSurface,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Actions
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    onSelected: (v) {
                      switch (v) {
                        case 'delete':
                          onDelete?.call();
                          break;
                        case 'open':
                          onTap?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'open',
                        child: _MenuItem(
                          icon: Icons.open_in_new,
                          label: 'Open details',
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: _MenuItem(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          danger: true,
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_horiz,
                      color: theme.iconTheme.color?.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right,
                    color: theme.iconTheme.color?.withOpacity(0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).textTheme.bodyMedium?.color;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
