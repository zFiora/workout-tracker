import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:workout_tracker/common/formatters/duarationFormatter.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/units/weight_unit.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_geometry.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_painter.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_overlay.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/services/muscle_summary_service.dart';
import 'package:workout_tracker/home/session/services/workout_summary_stats.dart';

// ── Data preparation (pure) ──────────────────────────────────────────────────

/// Everything the exported image shows, resolved to display strings up front
/// so the renderer does no formatting and this can be unit-tested.
class RecapExportData {
  const RecapExportData({
    required this.title,
    required this.dateLabel,
    required this.stats,
    required this.primary,
    required this.secondary,
  });

  factory RecapExportData.from({
    required WorkoutHistoryEntry entry,
    required MuscleSummary summary,
    required int prCount,
    required WeightUnit weightUnit,
  }) {
    final s = WorkoutSummaryStats.fromEntry(entry);
    return RecapExportData(
      title: entry.templateName.isEmpty ? 'Workout' : entry.templateName,
      dateLabel: DateFormat('EEE d MMM yyyy').format(entry.startedAt),
      stats: [
        (label: 'Duration', value: hhmmss(s.duration)),
        (label: 'Sets', value: '${s.workingSets}'),
        (label: 'Volume', value: weightUnit.formatWithUnit(s.volumeKg)),
        // PRs replace the exercise count only when there were any.
        if (prCount > 0)
          (label: 'PRs', value: '$prCount')
        else
          (label: 'Exercises', value: '${s.exercisesWithSets}'),
      ],
      primary: {
        for (final m in Muscle.values)
          if (summary.primary.contains(m)) m,
      },
      secondary: {
        for (final m in Muscle.values)
          if (summary.secondary.contains(m)) m,
      },
    );
  }

  final String title;
  final String dateLabel;
  final List<({String label, String value})> stats;

  /// In [Muscle] declaration order (roughly head to toe).
  final Set<Muscle> primary;
  final Set<Muscle> secondary;

  String get primaryLabel => primary.map((m) => m.displayName).join('  ·  ');
  String get secondaryLabel =>
      secondary.map((m) => m.displayName).join('  ·  ');
}

// ── Rendering ────────────────────────────────────────────────────────────────

/// Draws the share image directly with `dart:ui` (not a screenshot of the
/// UI): a 1080×1920 story-format card with the photo + overlay (or the body
/// map when there's no photo), the workout title/date, stats and muscles.
abstract final class RecapImageRenderer {
  static const size = Size(1080, 1920);

  /// The 4:5 photo panel — same aspect as the in-app preview, so
  /// [MuscleOverlayLayout] places the overlay identically in both.
  static const panel = Rect.fromLTWH(48, 150, 984, 1230);

  static Future<Uint8List> renderPng(
    RecapExportData data, {
    ui.Image? photo,
    OverlayConfig overlay = OverlayConfig.defaults,
  }) async {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), data, photo: photo, overlay: overlay);
    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  static void paint(
    Canvas canvas,
    RecapExportData data, {
    ui.Image? photo,
    OverlayConfig overlay = OverlayConfig.defaults,
  }) {
    // Background: deep ink with a soft azure glow behind the panel.
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.ink);
    canvas.drawCircle(
      const Offset(540, 700),
      760,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(540, 700), 760, [
          AppColors.volt.withValues(alpha: 0.22),
          AppColors.volt.withValues(alpha: 0),
        ]),
    );

    // Header: wordmark + date.
    _text(
      canvas,
      'ZLIFT',
      const Offset(56, 64),
      size: 40,
      weight: FontWeight.w800,
      color: AppColors.volt,
      letterSpacing: 10,
    );
    _text(
      canvas,
      data.dateLabel.toUpperCase(),
      const Offset(1024, 74),
      size: 26,
      weight: FontWeight.w700,
      color: AppColors.textMid,
      letterSpacing: 3,
      align: TextAlign.right,
    );

    _paintPanel(canvas, data, photo, overlay);

    // Title block.
    var y = panel.bottom + 56;
    _text(
      canvas,
      'WORKOUT COMPLETE',
      Offset(56, y),
      size: 26,
      weight: FontWeight.w800,
      color: AppColors.volt,
      letterSpacing: 6,
    );
    y += 44;
    _text(
      canvas,
      data.title,
      Offset(56, y),
      size: 64,
      weight: FontWeight.w800,
      color: AppColors.textHi,
      maxWidth: 968,
    );

    // Stats row.
    y += 108;
    final colW = 968 / data.stats.length;
    for (var i = 0; i < data.stats.length; i++) {
      final x = 56 + i * colW;
      _text(
        canvas,
        data.stats[i].value,
        Offset(x, y),
        size: 42,
        weight: FontWeight.w800,
        color: AppColors.textHi,
        maxWidth: colW - 16,
      );
      _text(
        canvas,
        data.stats[i].label.toUpperCase(),
        Offset(x, y + 56),
        size: 22,
        weight: FontWeight.w700,
        color: AppColors.textLow,
        letterSpacing: 2,
      );
    }

    // Muscles.
    y += 132;
    if (data.primary.isNotEmpty) {
      _dot(canvas, Offset(64, y + 18), AppColors.volt);
      _text(
        canvas,
        data.primaryLabel,
        Offset(88, y),
        size: 30,
        weight: FontWeight.w700,
        color: AppColors.textHi,
        maxWidth: 936,
      );
      y += 50;
    }
    if (data.secondary.isNotEmpty) {
      _dot(canvas, Offset(64, y + 18), const Color(0xFF9DBEFF));
      _text(
        canvas,
        data.secondaryLabel,
        Offset(88, y),
        size: 30,
        weight: FontWeight.w600,
        color: AppColors.textMid,
        maxWidth: 936,
      );
    }
  }

  static void _paintPanel(
    Canvas canvas,
    RecapExportData data,
    ui.Image? photo,
    OverlayConfig overlay,
  ) {
    final rrect = RRect.fromRectAndRadius(panel, const Radius.circular(48));
    canvas
      ..save()
      ..clipRRect(rrect);

    if (photo != null) {
      final imageSize = Size(photo.width.toDouble(), photo.height.toDouble());
      canvas.drawImageRect(
        photo,
        MuscleOverlayLayout.coverSourceRect(imageSize, panel.size),
        panel,
        Paint()..filterQuality = FilterQuality.high,
      );
      // Same scrim as the in-app preview/editor, only when the overlay shows.
      if (overlay.visible) {
        canvas.drawRect(
          panel,
          Paint()
            ..shader = ui.Gradient.linear(
              panel.topCenter,
              panel.bottomCenter,
              PhotoOverlayScrim.scrimColors,
              PhotoOverlayScrim.scrimStops,
            ),
        );
      }
      canvas
        ..save()
        ..translate(panel.left, panel.top);
      MuscleOverlayPainter(
        primary: data.primary,
        secondary: data.secondary,
        opacity: overlay.opacity,
        view: overlay.view,
        transform: overlay.transform,
      ).paint(canvas, panel.size);
      canvas.restore();
    } else {
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = ui.Gradient.linear(panel.topCenter, panel.bottomCenter, [
            AppColors.surface2,
            AppColors.surface1,
          ]),
      );
      // No photo to line up with, so centre the figures vertically instead of
      // using the bottom-aligned overlay placement.
      final rects = MuscleOverlayLayout.figureRects(
        panel.size,
        OverlayView.both,
      );
      final dy = (panel.height - rects.first.height) / 2 - rects.first.top;
      for (var i = 0; i < rects.length; i++) {
        canvas
          ..save()
          ..translate(
            panel.left + rects[i].left,
            panel.top + rects[i].top + dy,
          );
        MuscleMapPainter(
          side: i == 0 ? BodySide.front : BodySide.back,
          primary: data.primary,
          secondary: data.secondary,
          colors: const MuscleMapColors(
            body: AppColors.surface3,
            neutral: Color(0xFF34405E),
            primary: AppColors.volt,
            secondary: Color(0xFF2F4F8F),
            separator: AppColors.surface1,
          ),
          glow: true,
        ).paint(canvas, rects[i].size);
        canvas.restore();
      }
    }
    canvas.restore();

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.line,
    );
  }

  static void _dot(Canvas canvas, Offset c, Color color) =>
      canvas.drawCircle(c, 9, Paint()..color = color);

  static void _text(
    Canvas canvas,
    String text,
    Offset at, {
    required double size,
    required FontWeight weight,
    required Color color,
    double letterSpacing = 0,
    double maxWidth = 968,
    TextAlign align = TextAlign.left,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: letterSpacing,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final dx = align == TextAlign.right ? at.dx - tp.width : at.dx;
    tp.paint(canvas, Offset(dx, at.dy));
    tp.dispose();
  }
}

/// Decodes a local photo for the export, downscaled to at most [maxWidth]
/// pixels wide to keep memory bounded. EXIF orientation is applied by the
/// engine's decoder.
Future<ui.Image> decodePhotoForExport(File file, {int maxWidth = 1600}) async {
  final codec = await ui.instantiateImageCodec(
    await file.readAsBytes(),
    targetWidth: maxWidth,
    allowUpscaling: false,
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

// ── Sharing ──────────────────────────────────────────────────────────────────

typedef ShareImage =
    Future<void> Function(
      Uint8List png, {
      required String fileName,
      required String subject,
      Rect? origin,
    });

/// Writes the PNG to the app's temp directory and opens the native share
/// sheet. The image only leaves the device if the user picks a target.
Future<void> shareRecapImage(
  Uint8List png, {
  required String fileName,
  required String subject,
  Rect? origin,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(png, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'image/png')],
      subject: subject,
      sharePositionOrigin: origin,
    ),
  );
}
