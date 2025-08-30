import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/templates/templatesViewModel.dart';
import 'package:workout_tracker/home/templates/widgets/createTemplatePage.dart';
import 'package:workout_tracker/home/templates/widgets/templateActionMenu.dart';
import 'package:workout_tracker/home/templates/widgets/templateCard.dart';
import 'package:workout_tracker/home/templates/widgets/viewTemplatePage.dart';

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final templatesVM = context.watch<TemplatesViewModel>();
    final exercises = ExercisesViewModel.all;

    return MyCustomeScaffoldView(
      title: 'Templates',
      body: Column(
        children: [
          const SizedBox(height: 12),

          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: templatesVM.templates.length,
              itemBuilder: (context, index) {
                final template = templatesVM.templates[index];

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
                              builder: (_) =>
                                  ViewTemplatePage(template: template),
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
                        // Provide a picker for "Change icon"
                        pickIcon: (ctx) async {
                          // simple bottom sheet that returns the chosen asset path
                          final icons = const [
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

                          return await showModalBottomSheet<String>(
                            context: ctx,
                            showDragHandle: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (c) {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: GridView.builder(
                                  itemCount: icons.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                      ),
                                  itemBuilder: (_, i) {
                                    final path = icons[i];
                                    final selected = path == template.iconPath;
                                    return GestureDetector(
                                      onTap: () => Navigator.pop(c, path),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: selected
                                                ? Colors.teal
                                                : Colors.grey,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Image.asset(path),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
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
