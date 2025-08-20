import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/templates/templatesViewModel.dart';
import 'package:workout_tracker/home/templates/widgets/createTemplatePage.dart';
import 'package:workout_tracker/home/templates/widgets/viewTemplatePage.dart';

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
              // We no longer expect a returned template; CreateTemplatePage writes to Hive.
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateTemplatePage(exercises: exercises),
                ),
              );
              // No need to call templatesVM.addTemplate(...); Hive + ViewModel already updated.
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
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: templatesVM.templates.length,
              itemBuilder: (context, index) {
                final template = templatesVM.templates[index];

                Future<void> _confirmDelete() async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete template?'),
                      content: Text(
                        '“${template.name}” will be removed. This cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await templatesVM.deleteTemplate(template);
                    // Optional: toast/snackbar
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Template deleted')),
                      );
                    }
                  }
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewTemplatePage(template: template),
                      ),
                    );
                  },
                  onLongPress: _confirmDelete, // <— long-press to delete
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
                          '${template.exerciseIds.length} exercises', // updated already
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
