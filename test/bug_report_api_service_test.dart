// Client-side contract with BugReportsController.Create: screenshot rules,
// multipart field names, and the device/app context attached to a report.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/support/services/bug_report_api_service.dart';
import 'package:workout_tracker/home/support/services/device_context.dart';
import 'package:workout_tracker/home/support/services/screenshot_validator.dart';

void main() {
  group('ScreenshotValidator.validate', () {
    test('accepts jpg, jpeg, png and webp under 5MB', () {
      for (final ext in ['jpg', 'jpeg', 'png', 'webp', 'PNG']) {
        expect(
          ScreenshotValidator.validate(path: '/tmp/shot.$ext', sizeBytes: 1024),
          isNull,
          reason: ext,
        );
      }
    });

    test('rejects other formats and files without an extension', () {
      for (final path in ['/tmp/shot.heic', '/tmp/shot.gif', '/tmp/shot', '/tmp/shot.']) {
        expect(
          ScreenshotValidator.validate(path: path, sizeBytes: 1024),
          'Only JPEG, PNG and WebP screenshots are allowed.',
          reason: path,
        );
      }
    });

    test('enforces the 5MB limit inclusively', () {
      const limit = 5 * 1024 * 1024;
      expect(ScreenshotValidator.maxBytes, limit);
      expect(ScreenshotValidator.validate(path: 'a.png', sizeBytes: limit), isNull);
      expect(
        ScreenshotValidator.validate(path: 'a.png', sizeBytes: limit + 1),
        'Screenshot must be under 5MB.',
      );
    });
  });

  group('ScreenshotValidator.contentTypeFor', () {
    test('maps extensions to the MIME types the backend allows', () {
      expect(ScreenshotValidator.contentTypeFor('a.png'), 'image/png');
      expect(ScreenshotValidator.contentTypeFor('a.webp'), 'image/webp');
      expect(ScreenshotValidator.contentTypeFor('a.jpg'), 'image/jpeg');
      expect(ScreenshotValidator.contentTypeFor('a.JPEG'), 'image/jpeg');
    });
  });

  group('DeviceContext', () {
    tearDown(DeviceContext.resetForTesting);

    test('init() reads version and build number from the platform', () async {
      PackageInfo.setMockInitialValues(
        appName: 'workout_tracker',
        packageName: 'com.example.workout_tracker',
        version: '2.3.4',
        buildNumber: '17',
        buildSignature: '',
      );
      await DeviceContext.init();
      expect(DeviceContext.appVersion, '2.3.4+17');
    });

    test('formatVersion handles a missing build number and caps length', () {
      expect(DeviceContext.formatVersion('1.0.0', ''), '1.0.0');
      expect(DeviceContext.formatVersion('', '5'), isNull);
      expect(DeviceContext.formatVersion('9' * 60, '1')!.length, 50);
    });

    test('platform and deviceInfo describe the host within backend limits', () {
      expect(
        DeviceContext.platform,
        isIn(['android', 'ios', 'windows', 'macos', 'linux', 'web', 'unknown']),
      );
      expect(DeviceContext.platform.length, lessThanOrEqualTo(30));
      final info = DeviceContext.deviceInfo;
      expect(info, isNotNull);
      expect(info!.length, lessThanOrEqualTo(200));
      expect(info, startsWith(Platform.operatingSystem));
    });
  });

  group('BugReportApiService.buildFormData', () {
    late Directory tempDir;
    final service = BugReportApiService();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('bug_report_test');
      PackageInfo.setMockInitialValues(
        appName: 'workout_tracker',
        packageName: 'com.example.workout_tracker',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      await DeviceContext.init();
    });

    tearDown(() async {
      DeviceContext.resetForTesting();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('sends the exact text field names the backend binds', () async {
      final form = await service.buildFormData(
        title: 'Timer freezes',
        description: 'It froze.',
        appScreen: 'Account',
      );
      final fields = Map.fromEntries(form.fields);
      expect(fields['title'], 'Timer freezes');
      expect(fields['description'], 'It froze.');
      expect(fields['appScreen'], 'Account');
      expect(fields['appVersion'], '1.0.0+1');
      expect(fields['platform'], DeviceContext.platform);
      expect(fields['deviceInfo'], DeviceContext.deviceInfo);
      // Only fields BugReportsController.Create accepts; never a user id.
      expect(
        fields.keys.toSet().difference({
          'title', 'description', 'appVersion', 'platform',
          'deviceInfo', 'appScreen', 'errorDetails',
        }),
        isEmpty,
      );
      expect(form.files, isEmpty);
    });

    test('omits optional fields that have no value', () async {
      DeviceContext.resetForTesting();
      final form = await service.buildFormData(title: 't', description: 'd', appScreen: '');
      final keys = form.fields.map((e) => e.key).toSet();
      expect(keys, isNot(contains('appVersion')));
      expect(keys, isNot(contains('appScreen')));
    });

    test('attaches the screenshot as "screenshot" with an explicit image type', () async {
      final file = File('${tempDir.path}${Platform.pathSeparator}shot.png')
        ..writeAsBytesSync([0x89, 0x50, 0x4E, 0x47]);
      final form = await service.buildFormData(
        title: 't',
        description: 'd',
        screenshot: file,
      );
      expect(form.files, hasLength(1));
      final entry = form.files.single;
      expect(entry.key, 'screenshot');
      expect(entry.value.filename, 'shot.png');
      expect(entry.value.contentType?.mimeType, 'image/png');
      expect(entry.value.length, 4);
    });
  });

  group('BugReportApiException', () {
    test('keeps the ApiError reason, status and message', () {
      final e = BugReportApiException.from(
        const ApiError<void>('Session expired.', statusCode: 401, reason: NetworkReason.unauthorized),
      );
      expect(e.message, 'Session expired.');
      expect(e.statusCode, 401);
      expect(e.reason, NetworkReason.unauthorized);
      expect(e.toString(), 'Session expired.');
    });
  });
}
