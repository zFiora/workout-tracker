import 'dart:io';

import 'package:dio/dio.dart';
import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/support/models/bug_report.dart';
import 'package:workout_tracker/home/support/services/device_context.dart';
import 'package:workout_tracker/home/support/services/screenshot_validator.dart';

/// Thrown by [BugReportApiService] on any failed call. Keeps the
/// [NetworkReason] from the underlying [ApiError] so the UI can tell "no
/// network" apart from "server error" and "session expired".
class BugReportApiException implements Exception {
  const BugReportApiException(
    this.message, {
    this.reason = NetworkReason.unknown,
    this.statusCode,
  });

  factory BugReportApiException.from(ApiError e) =>
      BugReportApiException(e.message, reason: e.reason, statusCode: e.statusCode);

  final String message;
  final NetworkReason reason;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Backend contract: `BugReportsController` (WorkoutTrackerAPI). All three
/// endpoints are `[Authorize]`-protected; ownership is derived server-side
/// from the JWT, never sent by the client. Not `final` so tests can
/// subclass and override individual methods (see `FakeApi extends
/// WorkoutSessionsApiService` for the established pattern in this repo).
class BugReportApiService {
  final _client = ApiClient.instance;

  /// Split out from [submit] so tests can inspect the exact multipart
  /// fields/file sent to the backend without making a network call.
  Future<FormData> buildFormData({
    required String title,
    required String description,
    String? appScreen,
    File? screenshot,
  }) async {
    final fields = <String, dynamic>{
      'title': title,
      'description': description,
      if (DeviceContext.appVersion != null) 'appVersion': DeviceContext.appVersion,
      'platform': DeviceContext.platform,
      if (DeviceContext.deviceInfo != null) 'deviceInfo': DeviceContext.deviceInfo,
      if (appScreen != null && appScreen.isNotEmpty) 'appScreen': appScreen,
    };

    final formData = FormData.fromMap(fields);
    if (screenshot != null) {
      // Field name MUST be "screenshot" — confirmed against
      // BugReportsControllerTests.cs's MakeFile(..., "screenshot", ...).
      formData.files.add(
        MapEntry(
          'screenshot',
          await MultipartFile.fromFile(
            screenshot.path,
            filename: screenshot.uri.pathSegments.isNotEmpty
                ? screenshot.uri.pathSegments.last
                : 'screenshot.jpg',
            // Dio defaults an unset contentType to application/octet-stream,
            // which the backend's AllowedScreenshotTypes check would reject.
            contentType: DioMediaType.parse(
              ScreenshotValidator.contentTypeFor(screenshot.path),
            ),
          ),
        ),
      );
    }
    return formData;
  }

  Future<BugReportDetail> submit({
    required String title,
    required String description,
    String? appScreen,
    File? screenshot,
  }) async {
    final formData = await buildFormData(
      title: title,
      description: description,
      appScreen: appScreen,
      screenshot: screenshot,
    );
    final result = await _client.postMultipart('/api/bug-reports', formData);
    return switch (result) {
      ApiSuccess(:final data) => BugReportDetail.fromJson(data),
      ApiError e => throw BugReportApiException.from(e),
    };
  }

  /// Newest-first, per the backend's `GetMine` ordering.
  Future<List<BugReportSummary>> fetchMine() async {
    final result = await _client.get('/api/bug-reports/mine');
    return switch (result) {
      ApiSuccess(:final data) => (data as List)
          .cast<Map<String, dynamic>>()
          .map(BugReportSummary.fromJson)
          .toList(),
      ApiError e => throw BugReportApiException.from(e),
    };
  }

  Future<BugReportDetail> fetchDetail(String id) async {
    final result = await _client.get('/api/bug-reports/mine/$id');
    return switch (result) {
      ApiSuccess(:final data) =>
        BugReportDetail.fromJson(data as Map<String, dynamic>),
      ApiError e => throw BugReportApiException.from(e),
    };
  }
}
