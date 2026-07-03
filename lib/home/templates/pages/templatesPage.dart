import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/core/services/sync_coordinator.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/templates/constants/templateIcons.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';
import 'package:workout_tracker/home/templates/pages/createTemplatePage.dart';
import 'package:workout_tracker/home/templates/widgets/templateActionMenu.dart';
import 'package:workout_tracker/home/templates/widgets/templateCard.dart';
import 'package:workout_tracker/home/templates/pages/viewTemplatePage.dart';

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});


  Future<String?> _pickIcon(BuildContext ctx, {required String current}) {
    final cs = Theme.of(ctx).colorScheme;
    return showModalBottomSheet<String>(
      context: ctx,
      builder: (c) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeader(title: 'Choose an icon'),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: TemplateIcons.icons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (_, i) {
                  final path = TemplateIcons.icons[i];
                  final selected = path == current;
                  return Pressable(
                    onTap: () => Navigator.pop(c, path),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary.withValues(alpha: 0.15)
                            : cs.surfaceContainerHigh,
                        border: Border.all(
                          color: selected ? cs.primary : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Image.asset(path),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareTemplate(
    BuildContext context,
    String templateId,
    Map<String, dynamic> templateJson,
  ) async {
    final isOnline = context.read<AppManager>().isOnline;
    if (!isOnline) {
      Mycustomsnackbar.show(
        context,
        message: 'Sign in to share templates',
      );
      return;
    }

    final ok = await SyncCoordinator().shareTemplate(templateJson);

    if (!context.mounted) return;
    Mycustomsnackbar.show(
      context,
      message: ok ? 'Template shared with friends' : 'Share failed. Try again.',
      type: ok ? SnackbarType.success : SnackbarType.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TemplatesViewModel>();
    final templates = vm.templates;
    final exercises = ExercisesViewModel.all;

    void openCreate() => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateTemplatePage(exercises: exercises),
          ),
        );

    return MyCustomeScaffoldView(
      title: 'Workouts',
      body: Column(
        children: [
          Expanded(
            child: templates.isEmpty
                ? EmptyState(
                    icon: Icons.fitness_center_rounded,
                    title: 'No workouts yet',
                    message:
                        'Build your first template and it becomes\na one-tap start for every session.',
                    actionLabel: 'Create template',
                    onAction: openCreate,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return FadeRiseIn(
                        index: index,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned.fill(
                              child: TemplateCard(
                                template: template,
                                onOpen: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ViewTemplatePage(template: template),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: TemplateActionsMenu(
                                template: template,
                                pickIcon: (ctx) =>
                                    _pickIcon(ctx, current: template.iconPath),
                                onShare: () => _shareTemplate(
                                  context,
                                  template.id,
                                  template.toJson(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (templates.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: VoltButton(
                  label: 'New Template',
                  icon: Icons.add_rounded,
                  onPressed: openCreate,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
