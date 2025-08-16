import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/templates/templatesViewModel.dart';
import 'package:workout_tracker/home/templates/widgets/createTemplatePage.dart';
import 'package:workout_tracker/home/templates/widgets/viewTemplatePage.dart'; // create this page to show template

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final templatesVM = context.watch<TemplatesViewModel>();
    final exercises = context.read<ExercisesViewModel>().exercises;

    return MyCustomeScaffoldView(
      title: 'Templates',
      body: Column(
        children: [
          const SizedBox(height: 12),
          MyCustomButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateTemplatePage(exercises: exercises),
                ),
              );
              if (result != null) {
                templatesVM.addTemplate(result);
              }
            },
            label: 'Add new Template',
            icon: Icons.add,
            iconPosition: IconPosition.right,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // two boxes per row
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1, // square boxes
              ),
              itemCount: templatesVM.templates.length,
              itemBuilder: (context, index) {
                final template = templatesVM.templates[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewTemplatePage(template: template),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(template.iconPath, width: 48, height: 48),
                        const SizedBox(height: 8),
                        Text(
                          template.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${template.exercises.length} exercises',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
