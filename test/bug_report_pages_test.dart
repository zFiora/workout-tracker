// Widget tests for the bug-report screens, driven by a fake
// BugReportApiService (no network).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/support/models/bug_report.dart';
import 'package:workout_tracker/home/support/services/bug_report_api_service.dart';
import 'package:workout_tracker/home/support/widgets/bug_report_detail_page.dart';
import 'package:workout_tracker/home/support/widgets/my_bug_reports_page.dart';
import 'package:workout_tracker/home/support/widgets/report_bug_page.dart';

/// 1x1 transparent PNG.
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

class FakeBugReportApi extends BugReportApiService {
  Future<BugReportDetail> Function()? onSubmit;
  final List<Future<List<BugReportSummary>> Function()> mineResponses = [];
  Future<BugReportDetail> Function()? onDetail;

  int submitCalls = 0;
  int mineCalls = 0;
  String? lastTitle;
  String? lastDescription;

  @override
  Future<BugReportDetail> submit({
    required String title,
    required String description,
    String? appScreen,
    File? screenshot,
  }) {
    submitCalls++;
    lastTitle = title;
    lastDescription = description;
    return onSubmit!();
  }

  @override
  Future<List<BugReportSummary>> fetchMine() {
    final i = mineCalls++;
    return mineResponses[i < mineResponses.length ? i : mineResponses.length - 1]();
  }

  @override
  Future<BugReportDetail> fetchDetail(String id) => onDetail!();
}

BugReportDetail detail({String? screenshotBase64, String id = 'abcdef123456'}) =>
    BugReportDetail.fromJson({
      'id': id,
      'title': 'Timer freezes',
      'description': 'It froze on the rest screen.',
      'status': 'InProgress',
      'priority': 'High',
      'platform': 'android',
      'appVersion': '1.0.0+1',
      'appScreen': 'Account',
      'screenshotBase64': ?screenshotBase64,
      'screenshotContentType': screenshotBase64 == null ? null : 'image/png',
      'createdAt': '2026-09-20T10:15:00Z',
      'updatedAt': '2026-09-21T08:00:00Z',
    });

BugReportSummary summary(String id, String title, String status) => BugReportSummary.fromJson({
      'id': id,
      'title': title,
      'status': status,
      'priority': 'Medium',
      'hasScreenshot': false,
      'createdAt': '2026-09-20T10:15:00Z',
    });

/// Host screen with a button that pushes [page], so "the page closed" can be
/// asserted by the host becoming visible again.
Future<void> pumpHost(WidgetTester tester, Widget Function() page) async {
  // Tall phone-sized viewport so the whole form is laid out at once (the
  // form is a lazy ListView; off-screen fields would otherwise be disposed).
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => page())),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Taps the submit button by type — while loading it swaps its label for a
/// spinner, so finding it by text would miss exactly the case under test.
Future<void> tapSubmit(WidgetTester tester) async {
  final button = find.byType(VoltButton);
  await tester.ensureVisible(button);
  await tester.tap(button, warnIfMissed: false);
}

Future<void> fillForm(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Title'), '  Timer freezes ');
  await tester.enterText(find.widgetWithText(TextFormField, 'What happened?'), 'It froze.');
}

void main() {
  group('ReportBugPage', () {
    testWidgets('requires a title and description before submitting', (tester) async {
      final api = FakeBugReportApi();
      await pumpHost(tester, () => ReportBugPage(apiService: api));

      await tapSubmit(tester);
      await tester.pump();

      expect(find.text('A title is required.'), findsOneWidget);
      expect(find.text('A description is required.'), findsOneWidget);
      expect(api.submitCalls, 0);
    });

    testWidgets('sends trimmed title and folds expected behavior into description',
        (tester) async {
      final api = FakeBugReportApi()..onSubmit = () async => detail();
      await pumpHost(tester, () => ReportBugPage(apiService: api));
      await fillForm(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Expected behavior (optional)'),
        'Keep counting.',
      );

      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(api.lastTitle, 'Timer freezes');
      expect(
        api.lastDescription,
        'What happened:\nIt froze.\n\nExpected behavior:\nKeep counting.',
      );
    });

    testWidgets('success sheet Done closes the page', (tester) async {
      final api = FakeBugReportApi()..onSubmit = () async => detail();
      await pumpHost(tester, () => ReportBugPage(apiService: api));
      await fillForm(tester);

      await tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Report submitted'), findsOneWidget);
      expect(find.textContaining('#abcdef12'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportBugPage), findsNothing);
      expect(find.text('open'), findsOneWidget);
      expect(api.submitCalls, 1);
    });

    testWidgets('dismissing the success sheet any other way still closes the page',
        (tester) async {
      final api = FakeBugReportApi()..onSubmit = () async => detail();
      await pumpHost(tester, () => ReportBugPage(apiService: api));
      await fillForm(tester);

      await tapSubmit(tester);
      await tester.pumpAndSettle();
      expect(find.text('Report submitted'), findsOneWidget);

      // Same as the Android system back button popping the sheet route.
      Navigator.of(tester.element(find.text('Report submitted'))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(ReportBugPage), findsNothing);
      expect(api.submitCalls, 1);
    });

    testWidgets('a second tap while submitting does not send twice', (tester) async {
      final pending = Completer<BugReportDetail>();
      final api = FakeBugReportApi()..onSubmit = () => pending.future;
      await pumpHost(tester, () => ReportBugPage(apiService: api));
      await fillForm(tester);

      await tapSubmit(tester);
      await tester.pump();
      await tapSubmit(tester);
      await tester.pump();

      expect(api.submitCalls, 1);
      // Inputs are locked while the request is in flight.
      final title = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Title'),
          matching: find.byType(TextField),
        ),
      );
      expect(title.enabled, isFalse);

      pending.complete(detail());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(api.submitCalls, 1);
    });

    testWidgets('shows the error, keeps the form, and allows a retry', (tester) async {
      var attempt = 0;
      final api = FakeBugReportApi()
        ..onSubmit = () async {
          if (attempt++ == 0) {
            throw const BugReportApiException(
              "Can't reach the server. Check your connection.",
              reason: NetworkReason.noConnection,
            );
          }
          return detail();
        };
      await pumpHost(tester, () => ReportBugPage(apiService: api));
      await fillForm(tester);

      await tapSubmit(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text("Can't reach the server. Check your connection."), findsOneWidget);
      expect(find.byType(ReportBugPage), findsOneWidget);
      expect(find.text('Report submitted'), findsNothing);
      expect(find.text('It froze.'), findsOneWidget); // input preserved

      await tapSubmit(tester);
      await tester.pumpAndSettle();
      expect(api.submitCalls, 2);
      expect(find.text('Report submitted'), findsOneWidget);
    });

    testWidgets('an unexpected exception shows a generic message', (tester) async {
      final api = FakeBugReportApi()..onSubmit = () async => throw StateError('boom');
      await pumpHost(tester, () => ReportBugPage(apiService: api));
      await fillForm(tester);

      await tapSubmit(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Could not submit your report. Please try again.'), findsOneWidget);
    });
  });

  group('MyBugReportsPage', () {
    testWidgets('shows a spinner while loading', (tester) async {
      final pending = Completer<List<BugReportSummary>>();
      final api = FakeBugReportApi()..mineResponses.add(() => pending.future);
      await tester.pumpWidget(MaterialApp(home: MyBugReportsPage(apiService: api)));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(const []);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the empty state', (tester) async {
      final api = FakeBugReportApi()..mineResponses.add(() async => const []);
      await tester.pumpWidget(MaterialApp(home: MyBugReportsPage(apiService: api)));
      await tester.pumpAndSettle();

      expect(find.text('No bug reports yet'), findsOneWidget);
    });

    testWidgets('lists reports with their status', (tester) async {
      final api = FakeBugReportApi()
        ..mineResponses.add(() async => [
              summary('1', 'Timer freezes', 'InProgress'),
              summary('2', 'Chart is blank', 'Resolved'),
            ]);
      await tester.pumpWidget(MaterialApp(home: MyBugReportsPage(apiService: api)));
      await tester.pumpAndSettle();

      expect(find.text('Timer freezes'), findsOneWidget);
      expect(find.text('Chart is blank'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
    });

    for (final (reason, icon, title) in [
      (NetworkReason.noConnection, Icons.wifi_off_rounded, 'No connection'),
      (NetworkReason.timeout, Icons.wifi_off_rounded, 'No connection'),
      (NetworkReason.serverError, Icons.cloud_off_rounded, 'Something went wrong'),
      (NetworkReason.unauthorized, Icons.lock_outline, 'Session expired'),
    ]) {
      testWidgets('error state for ${reason.name}', (tester) async {
        final api = FakeBugReportApi()
          ..mineResponses.add(() async => throw BugReportApiException('msg-${reason.name}', reason: reason));
        await tester.pumpWidget(MaterialApp(home: MyBugReportsPage(apiService: api)));
        await tester.pumpAndSettle();

        expect(find.byIcon(icon), findsOneWidget);
        expect(find.text(title), findsOneWidget);
        expect(find.text('msg-${reason.name}'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });
    }

    testWidgets('Retry reloads after an error', (tester) async {
      final api = FakeBugReportApi()
        ..mineResponses.add(() async => throw const BugReportApiException(
              'Something went wrong on our end. Please try again.',
              reason: NetworkReason.serverError,
            ))
        ..mineResponses.add(() async => [summary('1', 'Timer freezes', 'Open')]);
      await tester.pumpWidget(MaterialApp(home: MyBugReportsPage(apiService: api)));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(api.mineCalls, 2);
      expect(find.text('Timer freezes'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('BugReportDetailPage', () {
    testWidgets('renders a decodable screenshot and opens it full-screen', (tester) async {
      final api = FakeBugReportApi()..onDetail = () async => detail(screenshotBase64: _pngBase64);
      await tester.pumpWidget(
        MaterialApp(home: BugReportDetailPage(reportId: 'r1', apiService: api)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Timer freezes'), findsOneWidget);
      final shot = find.byKey(const ValueKey('bug-report-screenshot'));
      expect(shot, findsOneWidget);

      // Image decoding runs on real async; give it a moment so the image
      // has a size to tap, and confirm it decoded (no errorBuilder fallback).
      // Decoding is a chain of engine futures; alternate real time with
      // frames so each step's callback gets delivered.
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      expect(tester.getSize(shot).height, greaterThan(0));
      expect(find.text('Could not display screenshot'), findsNothing);

      await tester.ensureVisible(shot);
      await tester.pumpAndSettle();
      await tester.tap(shot);
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('shows an explicit failure state for an undecodable screenshot',
        (tester) async {
      final api = FakeBugReportApi()..onDetail = () async => detail(screenshotBase64: 'not base64!!');
      await tester.pumpWidget(
        MaterialApp(home: BugReportDetailPage(reportId: 'r1', apiService: api)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not display screenshot'), findsOneWidget);
      expect(find.byKey(const ValueKey('bug-report-screenshot')), findsNothing);
    });

    testWidgets('has no screenshot section when the report has none', (tester) async {
      final api = FakeBugReportApi()..onDetail = () async => detail();
      await tester.pumpWidget(
        MaterialApp(home: BugReportDetailPage(reportId: 'r1', apiService: api)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Screenshot'), findsNothing);
      expect(find.text('Could not display screenshot'), findsNothing);
    });

    testWidgets('shows a session-expired error with retry', (tester) async {
      final api = FakeBugReportApi()
        ..onDetail = () async => throw const BugReportApiException(
              'Session expired. Please sign in again.',
              reason: NetworkReason.unauthorized,
              statusCode: 401,
            );
      await tester.pumpWidget(
        MaterialApp(home: BugReportDetailPage(reportId: 'r1', apiService: api)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Session expired'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
