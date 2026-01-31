import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
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
  ];

  Future<String?> _pickIcon(BuildContext ctx, {required String current}) async {
    final cs = Theme.of(ctx).colorScheme;

    return showModalBottomSheet<String>(
      context: ctx,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (c) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            itemCount: _icons.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (_, i) {
              final path = _icons[i];
              final selected = path == current;

              return GestureDetector(
                onTap: () => Navigator.pop(c, path),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? cs.primary : cs.surfaceVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(path),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TemplatesViewModel>();
    final templates = vm.templates;
    final exercises = ExercisesViewModel.all;

    return MyCustomeScaffoldView(
      title: 'Templates',
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
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
                        onOpen: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ViewTemplatePage(template: template),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: TemplateActionsMenu(
                        template: template,
                        pickIcon: (ctx) => _pickIcon(ctx, current: template.iconPath),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: MyCustomButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateTemplatePage(exercises: exercises),
                  ),
                );
              },
              fullWidth: true,
              label: 'Add new Template',
              icon: Icons.add,
              iconPosition: IconPosition.right,
            ),
          ),
        ],
      ),
    );
  }
}
