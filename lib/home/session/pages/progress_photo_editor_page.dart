import 'dart:io';

import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_overlay.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';

/// Full-screen editor for placing the muscle overlay on a progress photo:
/// drag to move, pinch to resize, twist to rotate, double-tap to reset.
///
/// Edits only an [OverlayConfig]; the photo file is never touched. Pops with
/// the new config when the user taps Save, or null when they close it.
/// [onShare] exports the *current* composition without saving it.
class ProgressPhotoEditorPage extends StatefulWidget {
  const ProgressPhotoEditorPage({
    super.key,
    required this.photo,
    required this.primary,
    required this.secondary,
    this.initial = OverlayConfig.defaults,
    this.onShare,
  });

  final File photo;
  final Set<Muscle> primary;
  final Set<Muscle> secondary;
  final OverlayConfig initial;
  final Future<void> Function(OverlayConfig config)? onShare;

  @override
  State<ProgressPhotoEditorPage> createState() =>
      _ProgressPhotoEditorPageState();
}

class _ProgressPhotoEditorPageState extends State<ProgressPhotoEditorPage> {
  late OverlayConfig _config = widget.initial;
  OverlayTransform _gestureStart = OverlayTransform.identity;
  Offset _focalStart = Offset.zero;
  bool _sharing = false;

  void _update(OverlayConfig config) => setState(() => _config = config);

  void _reset() =>
      _update(_config.copyWith(transform: OverlayTransform.identity));

  void _onScaleStart(ScaleStartDetails d) {
    // Re-fires whenever a finger is added/lifted, so each phase measures
    // from where the overlay is now — no jumps when a second finger lands.
    _gestureStart = _config.transform;
    _focalStart = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Size frame) {
    if (_config.view == OverlayView.none) return;
    _update(
      _config.copyWith(
        transform: OverlayTransform.fromGesture(
          _gestureStart,
          frame: frame,
          view: _config.view,
          translation: d.localFocalPoint - _focalStart,
          scaleFactor: d.scale,
          rotationDelta: d.rotation,
        ),
      ),
    );
  }

  void _setView(OverlayView view) {
    // Re-clamp: switching Both → Front moves the pivot. Clamping is
    // proportional, so a unit 4:5 frame gives the same result as the screen.
    final t = view == OverlayView.none
        ? _config.transform
        : _config.transform.clamped(
            const Size(1, 1 / MuscleOverlayLayout.photoAspect),
            view,
          );
    _update(_config.copyWith(view: view, transform: t));
  }

  Future<void> _share() async {
    final onShare = widget.onShare;
    if (onShare == null || _sharing) return;
    setState(() => _sharing = true);
    try {
      await onShare(_config);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildDarkTheme(),
      child: Builder(builder: _buildScaffold),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final editable = _config.view != OverlayView.none;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── top bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('overlay-editor-close'),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Muscle overlay',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('overlay-editor-reset'),
                    onPressed: editable && !_config.transform.isIdentity
                        ? _reset
                        : null,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ),

            // ── photo + overlay ──────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: MuscleOverlayLayout.photoAspect,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final frame = c.biggest;
                        return GestureDetector(
                          key: const ValueKey('overlay-editor-frame'),
                          behavior: HitTestBehavior.opaque,
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: (d) => _onScaleUpdate(d, frame),
                          onDoubleTap: editable ? _reset : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  widget.photo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const ColoredBox(
                                    color: AppColors.surface2,
                                    child: Center(
                                      child: Text(
                                        'Photo unavailable',
                                        style: TextStyle(
                                          color: AppColors.textMid,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_config.visible) const PhotoOverlayScrim(),
                                MuscleOverlay(
                                  primary: widget.primary,
                                  secondary: widget.secondary,
                                  config: _config,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            AnimatedOpacity(
              opacity: editable ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                'Drag to move · pinch to resize · twist to rotate',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textLow,
                ),
              ),
            ),

            // ── bottom toolbar ───────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.lineSoft),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModeSelector(value: _config.view, onChanged: _setView),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.opacity_rounded,
                        size: 18,
                        color: editable ? AppColors.textMid : AppColors.textLow,
                      ),
                      Expanded(
                        child: Slider(
                          key: const ValueKey('overlay-editor-opacity'),
                          value: _config.opacity,
                          min: OverlayConfig.minOpacity,
                          max: 1,
                          onChanged: editable
                              ? (v) => _update(_config.copyWith(opacity: v))
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${(_config.opacity * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.textMid,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (widget.onShare != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('overlay-editor-share'),
                            onPressed: _sharing ? null : _share,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.line),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                              ),
                            ),
                            icon: _sharing
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.ios_share_rounded, size: 20),
                            label: const Text('Share'),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey('overlay-editor-save'),
                          onPressed: () => Navigator.of(context).pop(_config),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: cs.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact Front / Back / Both / None pill selector.
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.value, required this.onChanged});

  final OverlayView value;
  final ValueChanged<OverlayView> onChanged;

  static const _labels = {
    OverlayView.front: 'Front',
    OverlayView.back: 'Back',
    OverlayView.both: 'Both',
    OverlayView.none: 'None',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final view in OverlayView.values)
            Expanded(
              child: GestureDetector(
                key: ValueKey('overlay-mode-${view.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(view),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: value == view ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _labels[view]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: value == view ? Colors.white : AppColors.textMid,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
