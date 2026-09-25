import 'package:workout_tracker/common/widgets/muscle_map/muscle_overlay.dart';
import 'package:workout_tracker/home/session/services/muscle_summary_service.dart';

/// Everything needed to re-show a finished workout's summary later, frozen at
/// the moment the workout was saved: the muscle summary as it was computed
/// then (not recomputed from today's exercise catalog), the PR count, and the
/// optional local progress photo.
///
/// Stored locally only (see `WorkoutRecapStore`), keyed by the workout's id —
/// never part of `WorkoutHistoryEntry` or its sync payload.
class WorkoutRecap {
  const WorkoutRecap({
    required this.workoutId,
    required this.summary,
    required this.prCount,
    required this.createdAt,
    this.photoFileName,
    this.overlay = OverlayConfig.defaults,
  });

  /// Bump when the stored shape changes; [fromJson] must keep reading older
  /// versions.
  /// v2 added [overlay] (v1 records read back with the default overlay).
  static const currentVersion = 2;

  final String workoutId;
  final MuscleSummary summary;
  final int prCount;
  final DateTime createdAt;

  /// File *name* inside the progress-photo folder, never an absolute path
  /// (iOS moves the app container between updates, which breaks absolute
  /// paths).
  final String? photoFileName;

  /// How the muscle overlay sits on the photo (mode, position, scale,
  /// rotation, opacity). The photo file itself is never modified; exports are
  /// rendered from photo + this config on demand.
  final OverlayConfig overlay;

  bool get hasPhoto => photoFileName != null && photoFileName!.isNotEmpty;

  WorkoutRecap withPhoto(String? fileName) => WorkoutRecap(
    workoutId: workoutId,
    summary: summary,
    prCount: prCount,
    createdAt: createdAt,
    photoFileName: fileName,
    overlay: overlay,
  );

  WorkoutRecap withOverlay(OverlayConfig config) => WorkoutRecap(
    workoutId: workoutId,
    summary: summary,
    prCount: prCount,
    createdAt: createdAt,
    photoFileName: photoFileName,
    overlay: config,
  );

  Map<String, dynamic> toJson() => {
    'version': currentVersion,
    'workoutId': workoutId,
    'summary': summary.toJson(),
    'prCount': prCount,
    'createdAt': createdAt.toIso8601String(),
    if (hasPhoto) 'photoFileName': photoFileName,
    'overlay': overlay.toJson(),
  };

  factory WorkoutRecap.fromJson(Map<String, dynamic> json) => WorkoutRecap(
    workoutId: json['workoutId'] as String? ?? '',
    summary: MuscleSummary.fromJson(
      Map<String, dynamic>.from(json['summary'] as Map? ?? const {}),
    ),
    prCount: (json['prCount'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    photoFileName: json['photoFileName'] as String?,
    overlay: OverlayConfig.fromJson(
      json['overlay'] == null
          ? null
          : Map<String, dynamic>.from(json['overlay'] as Map),
    ),
  );
}
