import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/pages/viewTemplatePage.dart';
import 'package:workout_tracker/home/templates/services/templates_api_service.dart';
import 'package:workout_tracker/home/templates/widgets/templateCard.dart';

class FriendTemplatesPage extends StatefulWidget {
  const FriendTemplatesPage({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  final String friendId;
  final String friendName;

  @override
  State<FriendTemplatesPage> createState() => _FriendTemplatesPageState();
}

class _FriendTemplatesPageState extends State<FriendTemplatesPage> {
  final _api = TemplatesApiService();
  List<WorkoutTemplateModel>? _templates;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final templates = await _api.fetchFriendTemplates(widget.friendId);
      if (!mounted) return;
      setState(() => _templates = templates);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget body;
    if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: TextStyle(color: cs.error)),
        ),
      );
    } else if (_templates == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_templates!.isEmpty) {
      body = Center(
        child: Text(
          '${widget.friendName} has no public templates yet',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    } else {
      body = GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _templates!.length,
        itemBuilder: (context, i) {
          final t = _templates![i];
          return TemplateCard(
            template: t,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ViewTemplatePage(template: t)),
            ),
          );
        },
      );
    }

    return MyCustomeScaffoldView(
      title: '${widget.friendName}\'s Templates',
      body: body,
    );
  }
}
