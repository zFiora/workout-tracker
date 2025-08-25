import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';
import 'package:workout_tracker/home/templates/templatesViewModel.dart';

enum TemplateAction { rename, changeIcon, delete }

class TemplateActionsMenu extends StatelessWidget {
  const TemplateActionsMenu({super.key, required this.template, this.pickIcon});

  final WorkoutTemplateModel template;

  final Future<String?> Function(BuildContext ctx)? pickIcon;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TemplatesViewModel>();

    Future<void> rename() async {
      final controller = TextEditingController(text: template.name);
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Rename template'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Template name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      final newName = controller.text.trim();
      if (ok == true && newName.isNotEmpty) {
        await vm.renameTemplate(template, newName);
      }
    }

    Future<void> changeIcon() async {
      if (pickIcon == null) return;
      final newPath = await pickIcon!(context);
      if (newPath != null && newPath.isNotEmpty) {
        await vm.changeIconPath(template, newPath);
      }
    }

    Future<void> deleteT() async {
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await vm.deleteTemplate(template);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Template deleted')));
        }
      }
    }

    return PopupMenuButton<TemplateAction>(
      tooltip: 'Template actions',
      onSelected: (action) async {
        switch (action) {
          case TemplateAction.rename:
            await rename();
            break;
          case TemplateAction.changeIcon:
            await changeIcon();
            break;
          case TemplateAction.delete:
            await deleteT();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: TemplateAction.rename,
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem(
          value: TemplateAction.changeIcon,
          child: Row(
            children: [
              Icon(Icons.image_outlined, size: 18),
              SizedBox(width: 8),
              Text('Change icon'),
            ],
          ),
        ),
        PopupMenuItem(
          value: TemplateAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
      child: const Icon(Icons.more_vert, size: 28),
    );
  }
}
