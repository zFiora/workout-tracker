import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:workout_tracker/common/formatters/duarationFormatter.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/units/weight_unit.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_view.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_overlay.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/pages/progress_photo_editor_page.dart';
import 'package:workout_tracker/home/session/recap/progress_photo_store.dart';
import 'package:workout_tracker/home/session/recap/recap_export.dart';
import 'package:workout_tracker/home/session/recap/workout_recap.dart';
import 'package:workout_tracker/home/session/recap/workout_recap_store.dart';
import 'package:workout_tracker/home/session/services/muscle_summary_service.dart';
import 'package:workout_tracker/home/session/services/workout_summary_stats.dart';

enum WorkoutSummaryMode { justCompleted, history }

/// Picks a photo and returns its (temporary) path, or null if cancelled.
typedef PickPhoto = Future<String?> Function(ImageSource source);

Future<String?> _pickWithImagePicker(ImageSource source) async {
  // Bounded + re-encoded: keeps files small and bakes in EXIF orientation.
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 2160,
    maxHeight: 2700,
    imageQuality: 90,
  );
  return picked?.path;
}

/// Workout recap: headline stats, the muscles worked on a front/back body
/// map, an optional local progress photo with a muscle overlay, and a
/// shareable image. Built from a saved [WorkoutHistoryEntry] plus its frozen
/// [WorkoutRecap], so History shows exactly what was shown after the workout.
class WorkoutSummaryPage extends StatefulWidget {
  const WorkoutSummaryPage({
    super.key,
    required this.entry,
    this.recap,
    this.prCount = 0,
    this.weightUnit = WeightUnit.kg,
    this.mode = WorkoutSummaryMode.justCompleted,
    this.computeSummary = computeMuscleSummary,
    this.recapStore,
    this.photoStore,
    this.pickPhoto = _pickWithImagePicker,
    this.shareImage = shareRecapImage,
  });

  final WorkoutHistoryEntry entry;

  /// The persisted recap. When present its summary is shown as saved and
  /// [computeSummary] is never called.
  final WorkoutRecap? recap;

  /// Used only when there's no [recap].
  final int prCount;
  final WeightUnit weightUnit;
  final WorkoutSummaryMode mode;

  /// Fallback when [recap] is null (e.g. it couldn't be created). Failures
  /// show the "unavailable" state; the workout is already saved by then.
  final MuscleSummary Function(WorkoutHistoryEntry entry) computeSummary;

  final WorkoutRecapStore? recapStore;
  final ProgressPhotoStore? photoStore;
  final PickPhoto pickPhoto;
  final ShareImage shareImage;

  @override
  State<WorkoutSummaryPage> createState() => _WorkoutSummaryPageState();
}

class _WorkoutSummaryPageState extends State<WorkoutSummaryPage> {
  late final WorkoutSummaryStats _stats = WorkoutSummaryStats.fromEntry(
    widget.entry,
  );
  late final MuscleSummary? _muscles = widget.recap?.summary ?? _safeCompute();
  late WorkoutRecap? _recap = widget.recap;

  WorkoutRecapStore get _recapStore => widget.recapStore ?? WorkoutRecapStore.I;
  ProgressPhotoStore get _photoStore =>
      widget.photoStore ?? ProgressPhotoStore.I;

  File? _photo;
  bool _photoMissing = false;
  bool _busyPhoto = false;
  bool _exporting = false;

  /// The saved overlay composition (defaults for recaps saved before the
  /// overlay editor existed).
  OverlayConfig get _overlay => _recap?.overlay ?? OverlayConfig.defaults;

  int get _prCount => _recap?.prCount ?? widget.prCount;

  MuscleSummary? _safeCompute() {
    try {
      return widget.computeSummary(widget.entry);
    } catch (e) {
      debugPrint('[WorkoutSummaryPage] muscle summary failed: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final name = _recap?.photoFileName;
    if (name == null) return;
    File? file;
    try {
      file = await _photoStore.resolve(name);
    } catch (e) {
      debugPrint('[WorkoutSummaryPage] could not load photo: $e');
    }
    if (!mounted) return;
    setState(() {
      _photo = file;
      _photoMissing = file == null;
    });
  }

  // ── photo actions ──────────────────────────────────────────────────────────

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _addPhoto(source);
  }

  Future<void> _addPhoto(ImageSource source) async {
    final recap = _recap;
    if (recap == null || _busyPhoto) return;
    setState(() => _busyPhoto = true);
    try {
      final path = await widget.pickPhoto(source);
      if (path == null) return; // cancelled
      final name = await _photoStore.persist(path);
      final updated = await _recapStore.setPhoto(recap, name);
      final file = await _photoStore.resolve(name);
      if (!mounted) return;
      setState(() {
        _recap = updated;
        _photo = file;
        _photoMissing = false;
      });
      // A fresh photo goes straight into the editor, starting from the
      // default placement.
      if (file != null) {
        _busyPhoto = false;
        await _openEditor(initial: OverlayConfig.defaults);
      }
    } catch (e) {
      debugPrint('[WorkoutSummaryPage] add photo failed: $e');
      if (mounted) {
        Mycustomsnackbar.show(
          context,
          message: "Couldn't add the photo.",
          type: SnackbarType.warning,
        );
      }
    } finally {
      if (mounted) setState(() => _busyPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final recap = _recap;
    if (recap == null || _busyPhoto) return;
    setState(() => _busyPhoto = true);
    try {
      final updated = await _recapStore.setPhoto(recap, null);
      if (!mounted) return;
      setState(() {
        _recap = updated;
        _photo = null;
        _photoMissing = false;
      });
    } finally {
      if (mounted) setState(() => _busyPhoto = false);
    }
  }

  /// Opens the overlay editor; persists the result only if the user saves.
  Future<void> _openEditor({OverlayConfig? initial}) async {
    final photo = _photo;
    final muscles = _muscles;
    if (photo == null || muscles == null || !mounted) return;
    final result = await Navigator.of(context).push<OverlayConfig>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ProgressPhotoEditorPage(
          photo: photo,
          primary: muscles.primary,
          secondary: muscles.secondary,
          initial: initial ?? _overlay,
          // Shares what's on screen without saving it.
          onShare: (config) => _export(config),
        ),
      ),
    );
    final recap = _recap;
    if (result == null || recap == null) return;
    final updated = await _recapStore.setOverlay(recap, result);
    if (mounted) setState(() => _recap = updated);
  }

  // ── export ─────────────────────────────────────────────────────────────────

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    await _export(_overlay, origin: origin);
  }

  /// Renders photo + [overlay] into the share image (the photo file is only
  /// read) and opens the share sheet.
  Future<void> _export(OverlayConfig overlay, {Rect? origin}) async {
    final muscles = _muscles;
    if (_exporting || muscles == null) return;
    setState(() => _exporting = true);
    try {
      final data = RecapExportData.from(
        entry: widget.entry,
        summary: muscles,
        prCount: _prCount,
        weightUnit: widget.weightUnit,
      );
      final photo = _photo == null ? null : await decodePhotoForExport(_photo!);
      final png = await RecapImageRenderer.renderPng(
        data,
        photo: photo,
        overlay: overlay,
      );
      photo?.dispose();
      await widget.shareImage(
        png,
        fileName:
            'zlift-${DateFormat('yyyyMMdd-HHmm').format(widget.entry.startedAt)}.png',
        subject: '${data.title} · ${data.dateLabel}',
        origin: origin,
      );
    } catch (e) {
      debugPrint('[WorkoutSummaryPage] export failed: $e');
      if (mounted) {
        Mycustomsnackbar.show(
          context,
          message: "Couldn't create the image.",
          type: SnackbarType.warning,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final muscles = _muscles;
    final completed = widget.mode == WorkoutSummaryMode.justCompleted;
    return MyCustomeScaffoldView(
      title: completed ? 'Workout Complete' : 'Workout Summary',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _HeroHeader(
            entry: widget.entry,
            stats: _stats,
            prCount: _prCount,
            weightUnit: widget.weightUnit,
            completed: completed,
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Muscle Groups Worked'),
          if (muscles != null && muscles.hasMuscles)
            _FadeIn(child: _MuscleCard(summary: muscles))
          else
            const _MusclesUnavailable(),
          if (_recap != null && muscles != null && muscles.hasMuscles) ...[
            const SizedBox(height: 24),
            const SectionHeader(title: 'Progress Photo'),
            if (_photo != null)
              _PhotoSection(
                photo: _photo!,
                summary: muscles,
                overlay: _overlay,
                busy: _busyPhoto,
                onEdit: () => _openEditor(),
                onChange: _choosePhoto,
                onRemove: _removePhoto,
              )
            else
              _AddPhotoCard(
                busy: _busyPhoto,
                missing: _photoMissing,
                onCamera: () => _addPhoto(ImageSource.camera),
                onGallery: () => _addPhoto(ImageSource.gallery),
              ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              if (muscles != null && muscles.hasMuscles) ...[
                Expanded(
                  child: Builder(
                    builder: (buttonContext) => OutlinedButton.icon(
                      key: const ValueKey('recap-share'),
                      onPressed: _exporting
                          ? null
                          : () => _share(buttonContext),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      icon: _exporting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.ios_share_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: VoltButton(
                  label: 'Done',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.entry,
    required this.stats,
    required this.prCount,
    required this.weightUnit,
    required this.completed,
  });

  final WorkoutHistoryEntry entry;
  final WorkoutSummaryStats stats;
  final int prCount;
  final WeightUnit weightUnit;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: tokens.cardBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(cs.primary.withValues(alpha: 0.22), cs.surface),
            cs.surfaceContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CheckBadge(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completed ? 'WORKOUT COMPLETE' : 'COMPLETED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEE d MMM · HH:mm').format(entry.startedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            entry.templateName.isEmpty ? 'Workout' : entry.templateName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final tiles = <Widget>[
                _StatTile(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: Text(hhmmss(stats.duration)),
                ),
                _StatTile(
                  icon: Icons.fitness_center_rounded,
                  label: 'Exercises',
                  value: _CountUp(stats.exercisesWithSets),
                ),
                _StatTile(
                  icon: Icons.repeat_rounded,
                  label: 'Working sets',
                  value: _CountUp(stats.workingSets),
                ),
                _StatTile(
                  icon: Icons.stacked_bar_chart_rounded,
                  label: 'Volume',
                  value: Text(weightUnit.formatWithUnit(stats.volumeKg)),
                ),
                if (prCount > 0)
                  _StatTile(
                    icon: Icons.emoji_events_rounded,
                    label: 'PRs',
                    value: _CountUp(prCount),
                    accent: tokens.warning,
                  ),
              ];
              const gap = 10.0;
              final w = (c.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [for (final t in tiles) SizedBox(width: w, child: t)],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(
        scale: t,
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.volt,
          boxShadow: [
            BoxShadow(
              color: AppColors.volt.withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent ?? cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DefaultTextStyle.merge(
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: accent ?? cs.onSurface,
            ),
            child: value,
          ),
        ],
      ),
    );
  }
}

/// Counts up to [value] once, on first build.
class _CountUp extends StatelessWidget {
  const _CountUp(this.value);
  final int value;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => Text('${v.round()}'),
  );
}

class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOut,
    builder: (_, t, c) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: c),
    ),
    child: child,
  );
}

// ── Muscles ──────────────────────────────────────────────────────────────────

class _MuscleCard extends StatelessWidget {
  const _MuscleCard({required this.summary});
  final MuscleSummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = [
      for (final m in Muscle.values)
        if (summary.primary.contains(m)) m,
    ];
    final secondary = [
      for (final m in Muscle.values)
        if (summary.secondary.contains(m)) m,
    ];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MuscleMapView(
              primary: summary.primary,
              secondary: summary.secondary,
              backgroundColor: cs.surfaceContainer,
              glow: true,
            ),
          ),
          const SizedBox(height: 14),
          const MuscleLegend(),
          const SizedBox(height: 18),
          if (primary.isNotEmpty)
            _MuscleGroup(
              label: 'PRIMARY',
              muscles: primary,
              summary: summary,
              isPrimary: true,
            ),
          if (secondary.isNotEmpty) ...[
            if (primary.isNotEmpty) const SizedBox(height: 14),
            _MuscleGroup(
              label: 'SECONDARY',
              muscles: secondary,
              summary: summary,
              isPrimary: false,
            ),
          ],
          if (summary.unrecognizedExercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'No muscle data for: ${summary.unrecognizedExercises.join(', ')}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _MuscleGroup extends StatelessWidget {
  const _MuscleGroup({
    required this.label,
    required this.muscles,
    required this.summary,
    required this.isPrimary,
  });

  final String label;
  final List<Muscle> muscles;
  final MuscleSummary summary;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in muscles)
              _MuscleChip(
                muscle: m,
                sets: summary.setsPerMuscle[m] ?? 0,
                isPrimary: isPrimary,
              ),
          ],
        ),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({
    required this.muscle,
    required this.sets,
    required this.isPrimary,
  });
  final Muscle muscle;
  final int sets;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = MuscleMapView.colorsOf(context);
    final accent = isPrimary ? colors.primary : colors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary
            ? cs.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: isPrimary ? 0.5 : 0.9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            muscle.displayName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(width: 6),
          Text(
            '$sets ${sets == 1 ? 'set' : 'sets'}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MusclesUnavailable extends StatelessWidget {
  const _MusclesUnavailable();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.accessibility_new_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Muscle summary unavailable',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  "We couldn't match this workout's exercises to muscle groups.",
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress photo ───────────────────────────────────────────────────────────

class _AddPhotoCard extends StatelessWidget {
  const _AddPhotoCard({
    required this.busy,
    required this.missing,
    required this.onCamera,
    required this.onGallery,
  });

  final bool busy;
  final bool missing;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.add_a_photo_outlined, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Progress Photo',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      missing
                          ? 'The saved photo is no longer on this device.'
                          : 'Private — stays on this device. Overlay the muscles you trained.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.photo,
    required this.summary,
    required this.overlay,
    required this.busy,
    required this.onEdit,
    required this.onChange,
    required this.onRemove,
  });

  final File photo;
  final MuscleSummary summary;
  final OverlayConfig overlay;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            key: const ValueKey('progress-photo-preview'),
            onTap: busy ? null : onEdit,
            child: Stack(
              children: [
                ProgressPhotoPreview(
                  photo: photo,
                  primary: summary.primary,
                  secondary: summary.secondary,
                  overlay: overlay,
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_with_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Tap to edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: busy ? null : onEdit,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Edit overlay'),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: busy ? null : onChange,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Change photo'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: busy ? null : onRemove,
                  style: TextButton.styleFrom(foregroundColor: cs.error),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Remove'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The photo in a fixed 4:5 frame (cover-cropped, never stretched) with the
/// saved overlay composition on top — the same frame, maths and painter as
/// the editor and the export, so all three match.
class ProgressPhotoPreview extends StatelessWidget {
  const ProgressPhotoPreview({
    super.key,
    required this.photo,
    required this.primary,
    required this.secondary,
    required this.overlay,
  });

  final File photo;
  final Set<Muscle> primary;
  final Set<Muscle> secondary;
  final OverlayConfig overlay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: MuscleOverlayLayout.photoAspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: cs.surfaceContainerHigh,
                child: Center(
                  child: Text(
                    'Photo unavailable',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            if (overlay.visible) ...[
              const PhotoOverlayScrim(),
              MuscleOverlay(
                primary: primary,
                secondary: secondary,
                config: overlay,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
