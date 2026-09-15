import 'dart:async';

import 'package:flutter/material.dart';

import 'coach_mark.dart';

/// Runs a coach-mark tutorial as a full-screen overlay above the whole app
/// (dim background + spotlight cutout + tooltip card with Back/Next/Skip).
///
/// Returns `true` if at least one step was actually shown to the user, so the
/// caller only records the tutorial as "seen" when something was displayed
/// (if every target happened to be missing, it can retry on the next visit).
///
/// The overlay absorbs all pointer events, so the spotlighted control cannot be
/// triggered while the tutorial is up, and normal navigation is untouched.
Future<bool> runCoachMarks(
  BuildContext context,
  List<CoachMarkStep> steps,
) {
  if (steps.isEmpty) return Future.value(false);

  final overlay = Overlay.of(context, rootOverlay: true);
  final completer = Completer<bool>();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _CoachMarkOverlay(
      steps: steps,
      onClose: (shown) {
        if (entry.mounted) entry.remove();
        if (!completer.isCompleted) completer.complete(shown);
      },
    ),
  );

  overlay.insert(entry);
  return completer.future;
}

class _CoachMarkOverlay extends StatefulWidget {
  const _CoachMarkOverlay({required this.steps, required this.onClose});

  final List<CoachMarkStep> steps;

  /// Called once when the tutorial ends; the bool is whether any step showed.
  final void Function(bool shown) onClose;

  @override
  State<_CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<_CoachMarkOverlay>
    with WidgetsBindingObserver {
  int _index = 0;
  Rect? _rect;
  bool _shown = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Resolve the first measurable step after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _activate(0, 1));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Rotation / resize / keyboard: re-measure the current target so the
    // spotlight tracks it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _closed) return;
      final rect = _measure(widget.steps[_index].targetKey);
      if (rect != null && rect != _rect) setState(() => _rect = rect);
    });
  }

  Rect? _measure(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    final rect = topLeft & box.size;
    if (rect.width <= 0 || rect.height <= 0) return null;
    return rect;
  }

  /// Walks from [start] in direction [dir] (+1 forward, -1 back) to the next
  /// step whose target can be scrolled into view and measured. Steps that
  /// can't be resolved are skipped. Running off the forward end finishes the
  /// tutorial; running off the back end just stays put.
  Future<void> _activate(int start, int dir) async {
    for (var i = start; i >= 0 && i < widget.steps.length; i += dir) {
      final step = widget.steps[i];
      final ctx = step.targetKey.currentContext;
      if (ctx != null) {
        try {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 250),
            alignment: 0.15,
          );
        } catch (_) {
          // No Scrollable ancestor (e.g. an app-bar action) — fine.
        }
        if (!mounted || _closed) return;
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || _closed) return;
        final rect = _measure(step.targetKey);
        if (rect != null) {
          setState(() {
            _index = i;
            _rect = rect;
            _shown = true;
          });
          return;
        }
      }
    }
    if (dir > 0) _finish(); // nothing left ahead → done
    // dir < 0 with nothing found → keep showing the current step.
  }

  void _next() => _activate(_index + 1, 1);
  void _back() => _activate(_index - 1, -1);

  void _finish() {
    if (_closed) return;
    _closed = true;
    widget.onClose(_shown);
  }

  void _skip() => _finish();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final step = widget.steps[_index];
    final rect = _rect;

    // Render nothing (and don't dim/absorb) until the first target is measured,
    // so a tutorial that resolves to zero visible targets never flashes.
    if (rect == null) return const SizedBox.shrink();

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Dim + spotlight cutout. A single opaque gesture layer over the
          // whole screen absorbs taps so the highlighted control can't fire.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // swallow taps on the dimmed area
              child: CustomPaint(
                painter: _SpotlightPainter(
                  hole: step.padding.inflateRect(rect),
                  radius: step.radius,
                  scrim: Colors.black.withValues(alpha: 0.72),
                  border: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),

          // Tooltip card.
          _positionedCard(size, rect, step),
        ],
      ),
    );
  }

  Widget _positionedCard(Size size, Rect rect, CoachMarkStep step) {
    // Place the card on whichever side of the target has more room.
    final below = rect.center.dy < size.height / 2;
    final card = _CoachCard(
      title: step.title,
      description: step.description,
      index: _index,
      total: widget.steps.length,
      onBack: _index > 0 ? _back : null,
      onNext: _next,
      onSkip: _skip,
      isLast: _index == widget.steps.length - 1,
    );

    if (below) {
      return Positioned(
        left: 16,
        right: 16,
        top: (rect.bottom + 14).clamp(0.0, size.height - 40),
        child: card,
      );
    }
    return Positioned(
      left: 16,
      right: 16,
      bottom: (size.height - rect.top + 14).clamp(0.0, size.height - 40),
      child: card,
    );
  }
}

/// Paints a translucent scrim over the whole screen with a rounded-rect hole
/// punched out around the current target.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.scrim,
    required this.border,
  });

  final Rect? hole;
  final double radius;
  final Color scrim;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final bg = Paint()..color = scrim;

    if (hole == null) {
      canvas.drawRect(full, bg);
      return;
    }

    final rrect = RRect.fromRectAndRadius(hole!, Radius.circular(radius));
    final scrimPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(scrimPath, bg);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = border.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole ||
      old.radius != radius ||
      old.scrim != scrim ||
      old.border != border;
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.title,
    required this.description,
    required this.index,
    required this.total,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.isLast,
  });

  final String title;
  final String description;
  final int index;
  final int total;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxCardHeight = MediaQuery.of(context).size.height * 0.6;

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: maxCardHeight),
        child: Material(
          color: cs.surface,
          elevation: 8,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1} of $total',
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      description,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: onSkip,
                      child: Text(
                        'Skip',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                    const Spacer(),
                    if (onBack != null)
                      TextButton(
                        onPressed: onBack,
                        child: const Text('Back'),
                      ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: onNext,
                      child: Text(isLast ? 'Done' : 'Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
