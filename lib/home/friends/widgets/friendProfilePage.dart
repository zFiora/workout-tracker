import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/friends/friendModel.dart';
import 'package:workout_tracker/home/friends/friendsViewModel.dart';
import 'package:workout_tracker/home/friends/widgets/friendTemplatesPage.dart';

class FriendProfilePage extends StatefulWidget {
  const FriendProfilePage({super.key, required this.preview});
  final FriendUser preview;

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  late FriendUser _user = widget.preview;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<FriendsViewModel>();
      final fresh = await vm.fetchProfile(widget.preview.id);
      if (!mounted) return;
      setState(() {
        if (fresh != null) _user = fresh;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MyCustomeScaffoldView(
      title: _user.name,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: cs.primaryContainer,
              backgroundImage: _user.avatarUrl != null
                  ? NetworkImage(_user.avatarUrl!)
                  : null,
              child: _user.avatarUrl == null
                  ? Icon(Icons.person, size: 40, color: cs.onPrimaryContainer)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Center(
            child: Text(
              '@${_user.username}',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          if (_loading) const Center(child: CircularProgressIndicator()),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatCard(
                icon: Icons.local_fire_department,
                color: Colors.orange,
                label: 'Current Streak',
                value: '${_user.currentStreak}',
              ),
              const SizedBox(width: 16),
              _StatCard(
                icon: Icons.emoji_events,
                color: Colors.amber,
                label: 'Best Streak',
                value: '${_user.bestStreak}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FriendTemplatesPage(
                  friendId: _user.id,
                  friendName: _user.name,
                ),
              ),
            ),
            icon: const Icon(Icons.fitness_center),
            label: const Text('View Templates'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
