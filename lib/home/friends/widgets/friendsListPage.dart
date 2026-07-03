import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/friends/friendModel.dart';
import 'package:workout_tracker/home/friends/friendsViewModel.dart';
import 'package:workout_tracker/home/friends/widgets/friendProfilePage.dart';

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});
  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FriendsViewModel>().refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsViewModel>();
    return MyCustomeScaffoldView(
      title: 'Friends',
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (vm.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!vm.loading && vm.friends.isEmpty) const _EmptyFriendsState(),
            ...vm.friends.map((u) => _FriendTile(user: u)),
          ],
        ),
      ),
    );
  }
}

class _EmptyFriendsState extends StatelessWidget {
  const _EmptyFriendsState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: EmptyState(
        icon: Icons.group_rounded,
        title: 'No friends yet',
        message: 'Tap "Add Friends" from Account\nto search by username.',
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.user});
  final FriendUser user;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FriendProfilePage(preview: user),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: cs.primaryContainer,
          backgroundImage: user.avatarUrl != null
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Icon(Icons.person, color: cs.onPrimaryContainer, size: 20)
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '@${user.username}',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: context.tokens.warning.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: context.tokens.warning.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 15,
                color: context.tokens.warning,
              ),
              const SizedBox(width: 4),
              Text(
                '${user.currentStreak}',
                style: TextStyle(
                  color: context.tokens.warning,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
