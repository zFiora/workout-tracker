// Parsing of the bug-report DTOs returned by WorkoutTrackerAPI's
// BugReportsController (camelCase JSON, nulls omitted — WhenWritingNull).

import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/home/support/models/bug_report.dart';

void main() {
  group('BugReportStatus parsing', () {
    test('maps every backend enum name (BugReportStatus.ToString())', () {
      expect(BugReportStatusParsing.parse('Open'), BugReportStatus.open);
      expect(BugReportStatusParsing.parse('InProgress'), BugReportStatus.inProgress);
      expect(BugReportStatusParsing.parse('Resolved'), BugReportStatus.resolved);
      expect(BugReportStatusParsing.parse('Closed'), BugReportStatus.closed);
    });

    test('is case-insensitive and falls back to unknown', () {
      expect(BugReportStatusParsing.parse('inprogress'), BugReportStatus.inProgress);
      expect(BugReportStatusParsing.parse('Triaged'), BugReportStatus.unknown);
      expect(BugReportStatusParsing.parse(null), BugReportStatus.unknown);
    });

    test('labels are user-facing', () {
      expect(BugReportStatus.inProgress.label, 'In Progress');
      expect(BugReportStatus.unknown.label, 'Unknown');
    });
  });

  group('BugReportPriority parsing', () {
    test('maps every backend enum name (BugReportPriority.ToString())', () {
      expect(BugReportPriorityParsing.parse('Low'), BugReportPriority.low);
      expect(BugReportPriorityParsing.parse('Medium'), BugReportPriority.medium);
      expect(BugReportPriorityParsing.parse('High'), BugReportPriority.high);
      expect(BugReportPriorityParsing.parse('Critical'), BugReportPriority.critical);
    });

    test('unrecognised or missing values fall back to unknown', () {
      expect(BugReportPriorityParsing.parse('Urgent'), BugReportPriority.unknown);
      expect(BugReportPriorityParsing.parse(''), BugReportPriority.unknown);
      expect(BugReportPriority.critical.label, 'Critical');
    });
  });

  group('BugReportSummary.fromJson', () {
    test('parses a full list item', () {
      final s = BugReportSummary.fromJson({
        'id': 'a1b2',
        'title': 'Timer freezes',
        'status': 'InProgress',
        'priority': 'High',
        'platform': 'android',
        'appVersion': '1.0.0+1',
        'hasScreenshot': true,
        'createdAt': '2026-09-20T10:15:00Z',
      });
      expect(s.id, 'a1b2');
      expect(s.title, 'Timer freezes');
      expect(BugReportStatusParsing.parse(s.status), BugReportStatus.inProgress);
      expect(BugReportPriorityParsing.parse(s.priority), BugReportPriority.high);
      expect(s.platform, 'android');
      expect(s.appVersion, '1.0.0+1');
      expect(s.hasScreenshot, isTrue);
      expect(s.createdAt.toUtc(), DateTime.utc(2026, 9, 20, 10, 15));
    });

    test('tolerates omitted nullable fields', () {
      final s = BugReportSummary.fromJson({
        'id': 'x',
        'title': 'T',
        'status': 'Open',
        'priority': 'Medium',
        'hasScreenshot': false,
        'createdAt': '2026-09-20T10:15:00Z',
      });
      expect(s.platform, isNull);
      expect(s.appVersion, isNull);
      expect(s.hasScreenshot, isFalse);
    });
  });

  group('BugReportDetail.fromJson', () {
    Map<String, dynamic> minimal() => {
          'id': 'r1',
          'title': 'Crash on save',
          'description': 'It crashed.',
          'status': 'Open',
          'priority': 'Medium',
          'createdAt': '2026-09-20T10:15:00Z',
          'updatedAt': '2026-09-21T08:00:00Z',
        };

    test('parses every field', () {
      final d = BugReportDetail.fromJson({
        ...minimal(),
        'appVersion': '1.0.0+1',
        'platform': 'ios',
        'deviceInfo': 'ios 18.0',
        'appScreen': 'Account',
        'errorDetails': 'StateError: bad state',
        'screenshotBase64': 'aGVsbG8=',
        'screenshotContentType': 'image/png',
      });
      expect(d.description, 'It crashed.');
      expect(d.appVersion, '1.0.0+1');
      expect(d.platform, 'ios');
      expect(d.deviceInfo, 'ios 18.0');
      expect(d.appScreen, 'Account');
      expect(d.errorDetails, 'StateError: bad state');
      expect(d.screenshotContentType, 'image/png');
      expect(d.hasScreenshot, isTrue);
      expect(d.updatedAt.toUtc(), DateTime.utc(2026, 9, 21, 8));
    });

    test('omitted nullable fields parse as null and hasScreenshot is false', () {
      final d = BugReportDetail.fromJson(minimal());
      expect(d.appVersion, isNull);
      expect(d.platform, isNull);
      expect(d.deviceInfo, isNull);
      expect(d.appScreen, isNull);
      expect(d.errorDetails, isNull);
      expect(d.screenshotBase64, isNull);
      expect(d.screenshotContentType, isNull);
      expect(d.hasScreenshot, isFalse);
    });

    test('an empty screenshot string does not count as a screenshot', () {
      final d = BugReportDetail.fromJson({...minimal(), 'screenshotBase64': ''});
      expect(d.hasScreenshot, isFalse);
    });

    test('ignores adminNotes even if a response ever contained it', () {
      final d = BugReportDetail.fromJson({...minimal(), 'adminNotes': 'internal'});
      // The model has no field for it; nothing in the parsed values carries it.
      expect(
        [d.title, d.description, d.errorDetails, d.deviceInfo, d.appScreen],
        isNot(contains('internal')),
      );
    });
  });
}
