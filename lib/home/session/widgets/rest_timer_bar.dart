import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/home/session/rest_timer_manager.dart';

/// Compact rest-timer strip. Renders nothing when idle, so it never gets in
/// the way; while resting it shows a progress bar, the countdown, and inline
/// controls (−15 / pause·resume / +15 / skip). Sits above the session's
/// bottom action bar and stays reachable while the user edits sets.
class RestTimerBar extends StatelessWidget {
  const RestTimerBar({super.key});

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final rest = context.watch<RestTimerManager>();
    if (!rest.isActive) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final finished = rest.isFinished;
    final accent = finished ? context.tokens.success : cs.primary;

    return Material(
      color: cs.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: finished ? 1 : rest.progress,
            minHeight: 3,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(accent),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            child: Row(
              children: [
                Icon(
                  finished ? Icons.check_circle_rounded : Icons.timer_rounded,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Text(
                  finished ? 'Rest complete' : 'Rest',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                if (!finished)
                  Text(
                    _fmt(rest.remaining),
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                const Spacer(),
                if (!finished) ...[
                  _MiniBtn(
                    label: '−15',
                    onTap: () => rest.subtractSeconds(15),
                  ),
                  _IconBtn(
                    icon: rest.isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    onTap: rest.isPaused ? rest.resume : rest.pause,
                  ),
                  _MiniBtn(
                    label: '+15',
                    onTap: () => rest.addSeconds(15),
                  ),
                ],
                TextButton(
                  onPressed: rest.skip,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(finished ? 'Dismiss' : 'Skip'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: cs.primary),
    );
  }
}
