import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/core/pb.dart';
import 'package:workout_tracker/core/services/sync_coordinator.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';
import 'package:workout_tracker/home/templates/pages/createTemplatePage.dart';
import 'package:workout_tracker/home/templates/widgets/templateActionMenu.dart';
import 'package:workout_tracker/home/templates/widgets/templateCard.dart';
import 'package:workout_tracker/home/templates/pages/viewTemplatePage.dart';

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  static const _icons = [
    "assets/workout_category/chest_emoji.png",
    "assets/workout_category/abs_emoji.png",
    "assets/workout_category/back_emoji.png",
    "assets/workout_category/shoulders_emoji.png",
    "assets/workout_category/tricep_emoji.png",
    "assets/workout_category/bicep_emoji.png",
    "assets/workout_category/cardio_emoji.png",
    "assets/workout_category/legs_emoji.png",
    "assets/workout_category/forearms_emoji.png",
    "assets/workout_category/muscular_forearms_emoji.png",
  ];

  Future<String?> _pickIcon(BuildContext ctx, {required String current}) {
    final cs = Theme.of(ctx).colorScheme;
    return showModalBottomSheet<String>(
      context: ctx,
      showDragHandle: true,
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Choose icon',
                style: Theme.of(c).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _icons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (_, i) {
                final path = _icons[i];
                final selected = path == current;
                return GestureDetector(
                  onTap: () => Navigator.pop(c, path),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.15)
                          : cs.surfaceContainerHighest,
                      border: Border.all(
                        color: selected ? cs.primary : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(path),
                  ),
                );
              },
            ),
          ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to share templates')),
      );
      return;
    }

    final pb = PB.I.pb;
    final userId = pb.authStore.record?.id ?? '';
    final coordinator = SyncCoordinator(pb: pb, userId: userId);
    final ok = await coordinator.shareTemplate(templateJson);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Template shared!' : 'Share failed. Try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TemplatesViewModel>();
    final templates = vm.templates;
    final exercises = ExercisesViewModel.all;
    return MyCustomeScaffoldView(
      title: 'Workouts',
      body: Column(
        children: [
          Expanded(
            child: templates.isEmpty
                ? _EmptyTemplatesState(
                    onAdd: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateTemplatePage(exercises: exercises),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                      return Stack(
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
                            top: 6,
                            right: 6,
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
                      );
                    },
                  ),
          ),
          if (templates.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateTemplatePage(exercises: exercises),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('New Template'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyTemplatesState extends StatelessWidget {
  const _EmptyTemplatesState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 48,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No workouts yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Create your first template to start\ntracking your sessions.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create Template'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
