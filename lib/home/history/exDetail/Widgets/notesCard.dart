import 'package:flutter/material.dart';
import 'package:workout_tracker/home/history/exDetail/Widgets/simpleCard.dart';
import 'package:workout_tracker/home/history/exDetail/exDetailViewModel.dart';

class NotesCard extends StatefulWidget {
  const NotesCard({super.key, required this.vm});
  final ExerciseDetailViewModel vm;

  @override
  State<NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends State<NotesCard> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final canSend = controller.text.trim().isNotEmpty;

    return SimpleCard(
      title: "Notes",
      valueWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: "Add a note (form cues, pain, setup...)",
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: canSend
                    ? () async {
                        final msg = controller.text.trim();
                        controller.clear();
                        setState(() {});
                        await vm.addNote(msg);
                        if (!mounted) return;
                        FocusScope.of(context).unfocus();
                      }
                    : null,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (vm.notes.isEmpty)
            const Text("No notes yet")
          else
            ...vm.notes.take(10).map(
                  (n) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(n.text),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
