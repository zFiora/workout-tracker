import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/support/models/bug_report.dart';
import 'package:workout_tracker/home/support/services/bug_report_api_service.dart';
import 'package:workout_tracker/home/support/widgets/bug_report_badges.dart';
import 'package:workout_tracker/home/support/widgets/bug_report_error_view.dart';

/// Full detail for a single report (`GET /api/bug-reports/mine/{id}`).
/// Renders every field `BugReportDetail` exposes — there is no `adminNotes`
/// field on the model to begin with, so it can never leak here (see
/// `BugReportDetail` doc comment).
class BugReportDetailPage extends StatefulWidget {
  BugReportDetailPage({
    super.key,
    required this.reportId,
    BugReportApiService? apiService,
  }) : apiService = apiService ?? BugReportApiService();

  final String reportId;
  final BugReportApiService apiService;

  @override
  State<BugReportDetailPage> createState() => _BugReportDetailPageState();
}

class _BugReportDetailPageState extends State<BugReportDetailPage> {
  bool _loading = true;
  String? _error;
  BugReportErrorKind _errorKind = BugReportErrorKind.server;
  BugReportDetail? _report;

  /// Decoded once per load (not per build). Null when the report has no
  /// screenshot or the base64 payload couldn't be decoded — see
  /// [_screenshotFailed] to tell those apart.
  Uint8List? _screenshotBytes;
  bool _screenshotFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await widget.apiService.fetchDetail(widget.reportId);
      if (!mounted) return;
      Uint8List? bytes;
      var failed = false;
      if (report.hasScreenshot) {
        try {
          bytes = base64Decode(report.screenshotBase64!);
        } catch (_) {
          failed = true;
        }
      }
      setState(() {
        _report = report;
        _screenshotBytes = bytes;
        _screenshotFailed = failed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is BugReportApiException ? e.message : 'Could not load this report.';
        _errorKind = BugReportErrorKindX.fromError(e);
        _loading = false;
      });
    }
  }

  void _openFullScreen(Uint8List bytes) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenScreenshot(bytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyCustomeScaffoldView(
      title: 'Bug Report',
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _report == null) {
      return BugReportErrorView(
        kind: _errorKind,
        message: _error ?? 'Could not load this report.',
        onRetry: _load,
      );
    }

    final r = _report!;
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('dd MMM yyyy, HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(r.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Row(
          children: [
            BugReportStatusChip(status: r.status),
            const SizedBox(width: 8),
            BugReportPriorityChip(priority: r.priority),
          ],
        ),
        const SizedBox(height: 20),
        SectionHeader(title: 'Description', padding: const EdgeInsets.only(bottom: 8)),
        AppCard(child: Text(r.description)),
        if (r.errorDetails != null && r.errorDetails!.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          SectionHeader(title: 'Error details', padding: const EdgeInsets.only(bottom: 8)),
          AppCard(
            child: Text(
              r.errorDetails!,
              style: TextStyle(fontFamily: 'monospace', color: cs.onSurfaceVariant),
            ),
          ),
        ],
        if (r.hasScreenshot) ...[
          const SizedBox(height: 20),
          SectionHeader(title: 'Screenshot', padding: const EdgeInsets.only(bottom: 8)),
          if (_screenshotFailed || _screenshotBytes == null)
            const _ScreenshotUnavailable()
          else
            GestureDetector(
              key: const ValueKey('bug-report-screenshot'),
              onTap: () => _openFullScreen(_screenshotBytes!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.memory(
                  _screenshotBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  // Valid base64 that isn't a decodable image still fails
                  // here, at paint time.
                  errorBuilder: (_, _, _) => const _ScreenshotUnavailable(),
                ),
              ),
            ),
        ],
        const SizedBox(height: 20),
        SectionHeader(title: 'Details', padding: const EdgeInsets.only(bottom: 8)),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Reported', value: df.format(r.createdAt)),
              _DetailRow(label: 'Last updated', value: df.format(r.updatedAt)),
              if (r.appScreen != null && r.appScreen!.isNotEmpty)
                _DetailRow(label: 'Screen', value: r.appScreen!),
              if (r.platform != null && r.platform!.isNotEmpty)
                _DetailRow(label: 'Platform', value: r.platform!),
              if (r.appVersion != null && r.appVersion!.isNotEmpty)
                _DetailRow(label: 'App version', value: r.appVersion!),
              if (r.deviceInfo != null && r.deviceInfo!.isNotEmpty)
                _DetailRow(label: 'Device', value: r.deviceInfo!, isLast: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.isLast = false});
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _ScreenshotUnavailable extends StatelessWidget {
  const _ScreenshotUnavailable();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not display screenshot',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenScreenshot extends StatelessWidget {
  const _FullScreenScreenshot({required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Screenshot'),
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Text(
              'Could not display screenshot',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
