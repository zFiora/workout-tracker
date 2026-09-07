import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/pages/editTemplatePage.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';

enum _Action { rename, changeIcon, editExercises, share, delete }

class TemplateActionsMenu extends StatelessWidget {
  const TemplateActionsMenu({
    super.key,
    required this.template,
    this.pickIcon,
    this.onShare,
  });

  final WorkoutTemplateModel template;
  final Future<String?> Function(BuildContext ctx)? pickIcon;
  final VoidCallback? onShare;

  Future<void> _rename(BuildContext context, TemplatesViewModel vm) async {
    // The text is captured inside the callback and returned as the dialog result
    // so we never call controller.dispose() from outside — the dialog's exit
    // animation is still running when showDialog returns, and disposing then
    // triggers _dependents.isEmpty assertion failure in ChangeNotifier.
    final controller = TextEditingController(text: template.name);

    final newName = await showDialog<String?>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Rename template'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Template name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(dialogCtx, text.isEmpty ? null : text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null) {
      await vm.renameTemplate(template, newName);
    }
  }

  Future<void> _changeIcon(BuildContext context, TemplatesViewModel vm) async {
    if (pickIcon == null) return;
    final newPath = await pickIcon!(context);
    if (newPath != null && newPath.isNotEmpty) {
      await vm.changeIconPath(template, newPath);
    }
  }

  Future<void> _editExercises(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTemplatePage(
          template: template,
          allExercises: ExercisesViewModel.all,
        ),
      ),
    );
  }

  // Deleting is already gated behind two deliberate taps (open the menu,
  // then Delete) — a third confirmation dialog on top is friction without
  // much extra safety. An Undo snackbar (same pattern as History) covers the
  // "oops" case better than a dialog would, without interrupting the flow.
  Future<void> _delete(BuildContext context, TemplatesViewModel vm) async {
    final deleted = template;
    await vm.deleteTemplate(deleted);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('"${deleted.name}" deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => vm.addTemplate(deleted),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TemplatesViewModel>();
    final isOnline = context.watch<AppManager>().isOnline;

    return PopupMenuButton<_Action>(
      tooltip: 'Template actions',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (action) async {
        switch (action) {
          case _Action.rename:
            await _rename(context, vm);
          case _Action.changeIcon:
            await _changeIcon(context, vm);
          case _Action.editExercises:
            await _editExercises(context);
          case _Action.share:
            onShare?.call();
          case _Action.delete:
            await _delete(context, vm);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _Action.rename,
          child: _MenuRow(icon: Icons.drive_file_rename_outline_rounded, label: 'Rename'),
        ),
        const PopupMenuItem(
          value: _Action.changeIcon,
          child: _MenuRow(icon: Icons.image_outlined, label: 'Change icon'),
        ),
        const PopupMenuItem(
          value: _Action.editExercises,
          child: _MenuRow(icon: Icons.edit_note_rounded, label: 'Edit template'),
        ),
        if (isOnline)
          const PopupMenuItem(
            value: _Action.share,
            child: _MenuRow(
              icon: Icons.share_outlined,
              label: 'Share with friends',
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _Action.delete,
          child: _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert, size: 20, color: Colors.white),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: c)),
      ],
    );
  }
}
