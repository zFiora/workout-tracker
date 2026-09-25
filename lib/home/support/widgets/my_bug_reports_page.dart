import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/support/models/bug_report.dart';
import 'package:workout_tracker/home/support/services/bug_report_api_service.dart';
import 'package:workout_tracker/home/support/widgets/bug_report_badges.dart';
import 'package:workout_tracker/home/support/widgets/bug_report_detail_page.dart';
import 'package:workout_tracker/home/support/widgets/bug_report_error_view.dart';
import 'package:workout_tracker/home/support/widgets/report_bug_page.dart';

/// Lists the signed-in user's own bug reports (`GET /api/bug-reports/mine`).
/// Self-contained `StatefulWidget` + injectable service, matching the rest
/// of this feature and the app's established pattern for one-off screens
/// that don't need a shared/global ViewModel (see `AddFriendPage`).
class MyBugReportsPage extends StatefulWidget {
  MyBugReportsPage({super.key, BugReportApiService? apiService})
      : apiService = apiService ?? BugReportApiService();

  final BugReportApiService apiService;

  @override
  State<MyBugReportsPage> createState() => _MyBugReportsPageState();
}

class _MyBugReportsPageState extends State<MyBugReportsPage> {
  bool _loading = true;
  String? _error;
  BugReportErrorKind _errorKind = BugReportErrorKind.server;
  List<BugReportSummary> _reports = const [];

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
      final reports = await widget.apiService.fetchMine();
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is BugReportApiException ? e.message : 'Could not load your reports.';
        _errorKind = BugReportErrorKindX.fromError(e);
        _loading = false;
      });
    }
  }

  Future<void> _openReportBug() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportBugPage(apiService: widget.apiService),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return MyCustomeScaffoldView(
      title: 'My Bug Reports',
      customAppBar: AppBar(
        title: const Text('My Bug Reports'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Report a bug',
            icon: const Icon(Icons.add_rounded),
            onPressed: _openReportBug,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _reports.isEmpty && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _reports.isEmpty) {
      return BugReportErrorView(kind: _errorKind, message: _error!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_reports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: Icons.bug_report_outlined,
                title: 'No bug reports yet',
                message: 'Reports you submit will show up here so you can\n'
                    'track their status.',
              ),
            )
          else
            ..._reports.map((r) => _BugReportTile(
                  report: r,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BugReportDetailPage(
                        reportId: r.id,
                        apiService: widget.apiService,
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _BugReportTile extends StatelessWidget {
  const _BugReportTile({required this.report, required this.onTap});
  final BugReportSummary report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Text(
          report.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              BugReportStatusChip(status: report.status),
              const SizedBox(width: 6),
              BugReportPriorityChip(priority: report.priority),
              const Spacer(),
              if (report.hasScreenshot)
                Icon(Icons.image_outlined, size: 16, color: cs.onSurfaceVariant),
            ],
          ),
        ),
        isThreeLine: false,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              df.format(report.createdAt),
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
