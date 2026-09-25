import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/support/services/bug_report_api_service.dart';
import 'package:workout_tracker/home/support/services/screenshot_validator.dart';

/// User-facing "Report a Bug" form. [appScreen] is a static label supplied
/// by the caller (e.g. "Account") — automatic in the sense that the user
/// never has to type it, not a live route tracker.
class ReportBugPage extends StatefulWidget {
  ReportBugPage({super.key, this.appScreen = 'Account', BugReportApiService? apiService})
      : apiService = apiService ?? BugReportApiService();

  final String appScreen;
  final BugReportApiService apiService;

  @override
  State<ReportBugPage> createState() => _ReportBugPageState();
}

class _ReportBugPageState extends State<ReportBugPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _expectedCtrl = TextEditingController();
  final _picker = ImagePicker();

  File? _screenshot;
  String? _screenshotError;
  bool _submitting = false;
  bool _submitted = false;
  String? _submitError;

  bool get _locked => _submitting || _submitted;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _expectedCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot(ImageSource source) async {
    // Downscale/re-compress on-device so full-resolution camera photos fit
    // comfortably under the backend's 5MB cap. image_picker only resizes
    // images larger than the bounds and only re-encodes formats it supports,
    // so the size check below still runs on whatever comes back.
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.length();
    final error = ScreenshotValidator.validate(path: picked.path, sizeBytes: bytes);
    if (!mounted) return;
    setState(() {
      if (error != null) {
        _screenshotError = error;
        _screenshot = null;
      } else {
        _screenshotError = null;
        _screenshot = File(picked.path);
      }
    });
  }

  void _showScreenshotSourceSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickScreenshot(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a screenshot/photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickScreenshot(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeScreenshot() {
    setState(() {
      _screenshot = null;
      _screenshotError = null;
    });
  }

  /// The backend's `description` is the only free-text field — "expected
  /// behavior" isn't a separate contract field, so it's folded into
  /// `description` as a labeled second section rather than inventing one.
  String _composeDescription() {
    final what = _descriptionCtrl.text.trim();
    final expected = _expectedCtrl.text.trim();
    if (expected.isEmpty) return what;
    return 'What happened:\n$what\n\nExpected behavior:\n$expected';
  }

  Future<void> _submit() async {
    // Duplicate-submit guard: in flight, or already accepted by the server.
    if (_locked) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final report = await widget.apiService.submit(
        title: _titleCtrl.text.trim(),
        description: _composeDescription(),
        appScreen: widget.appScreen,
        screenshot: _screenshot,
      );
      if (!mounted) return;
      // Stays true for the life of this page, so the form can never be sent
      // twice even if the success sheet is dismissed without tapping Done.
      setState(() {
        _submitting = false;
        _submitted = true;
      });
      await _showSuccessSheet(report.id);
      // However the sheet closed (Done, system back, …), leave the form.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e is BugReportApiException
            ? e.message
            : 'Could not submit your report. Please try again.';
      });
      Mycustomsnackbar.show(context, message: _submitError!, type: SnackbarType.warning);
    }
  }

  Future<void> _showSuccessSheet(String reportId) async {
    final cs = Theme.of(context).colorScheme;
    final shortId = reportId.length > 8 ? reportId.substring(0, 8) : reportId;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 18),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CircleAvatar(
              radius: 26,
              backgroundColor: context.tokens.success.withValues(alpha: 0.14),
              child: Icon(Icons.check_circle_rounded, color: context.tokens.success, size: 30),
            ),
            const SizedBox(height: 16),
            Text('Report submitted', style: Theme.of(sheetCtx).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Thanks for the report — reference #$shortId. '
              "We'll take a look and update its status.",
              textAlign: TextAlign.center,
              style: Theme.of(sheetCtx)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(sheetCtx),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MyCustomeScaffoldView(
      title: 'Report a Bug',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _titleCtrl,
              maxLength: 200,
              enabled: !_locked,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Short summary of the bug',
                prefixIcon: Icon(Icons.bug_report_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'A title is required.' : null,
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _descriptionCtrl,
              minLines: 4,
              maxLines: 8,
              enabled: !_locked,
              decoration: const InputDecoration(
                labelText: 'What happened?',
                hintText: 'Steps to reproduce, what you saw, etc.',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'A description is required.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _expectedCtrl,
              minLines: 2,
              maxLines: 4,
              enabled: !_locked,
              decoration: const InputDecoration(
                labelText: 'Expected behavior (optional)',
                hintText: 'What you expected to happen instead',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            Text('Screenshot (optional)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_screenshot != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.file(
                      _screenshot!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      children: [
                        _RoundIconButton(
                          icon: Icons.edit_outlined,
                          onTap: _locked ? null : _showScreenshotSourceSheet,
                        ),
                        const SizedBox(width: 6),
                        _RoundIconButton(
                          icon: Icons.close_rounded,
                          onTap: _locked ? null : _removeScreenshot,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _locked ? null : _showScreenshotSourceSheet,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add a screenshot'),
              ),
            if (_screenshotError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _screenshotError!,
                  style: TextStyle(color: cs.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 28),
            VoltButton(
              label: 'Submit Report',
              icon: Icons.send_rounded,
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
