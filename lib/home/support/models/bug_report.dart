/// Status values the backend can return for a bug report. Kept as an enum
/// on the client for exhaustive-switch safety in the UI; the wire format is
/// always the raw string (see [BugReportSummary.status] / [BugReportDetail.status]).
enum BugReportStatus { open, inProgress, resolved, closed, unknown }

extension BugReportStatusParsing on BugReportStatus {
  static BugReportStatus parse(String? raw) => switch ((raw ?? '').toLowerCase()) {
        'open' => BugReportStatus.open,
        'inprogress' => BugReportStatus.inProgress,
        'resolved' => BugReportStatus.resolved,
        'closed' => BugReportStatus.closed,
        _ => BugReportStatus.unknown,
      };

  String get label => switch (this) {
        BugReportStatus.open => 'Open',
        BugReportStatus.inProgress => 'In Progress',
        BugReportStatus.resolved => 'Resolved',
        BugReportStatus.closed => 'Closed',
        BugReportStatus.unknown => 'Unknown',
      };
}

/// Priority is server-owned — the client only ever displays it (see
/// AdminController.UpdateBugReport, which has no priority field either).
enum BugReportPriority { low, medium, high, critical, unknown }

extension BugReportPriorityParsing on BugReportPriority {
  static BugReportPriority parse(String? raw) => switch ((raw ?? '').toLowerCase()) {
        'low' => BugReportPriority.low,
        'medium' => BugReportPriority.medium,
        'high' => BugReportPriority.high,
        'critical' => BugReportPriority.critical,
        _ => BugReportPriority.unknown,
      };

  String get label => switch (this) {
        BugReportPriority.low => 'Low',
        BugReportPriority.medium => 'Medium',
        BugReportPriority.high => 'High',
        BugReportPriority.critical => 'Critical',
        BugReportPriority.unknown => 'Unknown',
      };
}

/// Row shown in "My Bug Reports" — mirrors `BugReportListItemDto` from the
/// backend. Deliberately excludes description/screenshot bytes/admin notes,
/// same as the backend's list endpoint.
class BugReportSummary {
  const BugReportSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.platform,
    required this.appVersion,
    required this.hasScreenshot,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String status;
  final String priority;
  final String? platform;
  final String? appVersion;
  final bool hasScreenshot;
  final DateTime createdAt;

  factory BugReportSummary.fromJson(Map<String, dynamic> j) => BugReportSummary(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        status: j['status'] as String? ?? 'Open',
        priority: j['priority'] as String? ?? 'Medium',
        platform: j['platform'] as String?,
        appVersion: j['appVersion'] as String?,
        hasScreenshot: j['hasScreenshot'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );
}

/// Full report — mirrors `BugReportDto` from the backend
/// (`BugReportsController.cs`). Deliberately has no `adminNotes` field: the
/// backend never sends it to this endpoint, and this DTO must never surface
/// it even if it did.
class BugReportDetail {
  const BugReportDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.appVersion,
    required this.platform,
    required this.deviceInfo,
    required this.appScreen,
    required this.errorDetails,
    required this.screenshotBase64,
    required this.screenshotContentType,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? appVersion;
  final String? platform;
  final String? deviceInfo;
  final String? appScreen;
  final String? errorDetails;
  final String? screenshotBase64;
  final String? screenshotContentType;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasScreenshot => screenshotBase64 != null && screenshotBase64!.isNotEmpty;

  factory BugReportDetail.fromJson(Map<String, dynamic> j) => BugReportDetail(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        status: j['status'] as String? ?? 'Open',
        priority: j['priority'] as String? ?? 'Medium',
        appVersion: j['appVersion'] as String?,
        platform: j['platform'] as String?,
        deviceInfo: j['deviceInfo'] as String?,
        appScreen: j['appScreen'] as String?,
        errorDetails: j['errorDetails'] as String?,
        screenshotBase64: j['screenshotBase64'] as String?,
        screenshotContentType: j['screenshotContentType'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );
}
