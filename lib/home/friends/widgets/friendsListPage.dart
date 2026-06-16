import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/core/pb.dart';
import 'package:workout_tracker/home/friends/friendsViewModel.dart';

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
            if (!vm.loading && vm.friends.isEmpty)
              _EmptyFriendsState(),
            ...vm.friends.map((u) => _FriendTile(user: u)),
          ],
        ),
      ),
    );
  }
}

class _EmptyFriendsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.group_outlined, size: 56, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No friends yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Friends" from Account to search by username.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.user});
  final RecordModel user;

  ImageProvider _resolveAvatar(String avatarField) {
    if (avatarField.isEmpty) {
      return const AssetImage('assets/logo/default_avatar.png');
    }
    // PocketBase stores avatar as a filename; construct the full file URL.
    final baseUrl = PB.I.pb.baseURL;
    final collectionId = user.collectionId;
    final recordId = user.id;
    return NetworkImage('$baseUrl/api/files/$collectionId/$recordId/$avatarField');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final username = user.getStringValue('name');
    final currentStreak = user.getIntValue('currentStreak');
    final avatarField = user.getStringValue('avatar');
    final avatarProvider = _resolveAvatar(avatarField);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: cs.primaryContainer,
          backgroundImage: avatarProvider,
          onBackgroundImageError: (_, _) {},
          child: avatarField.isEmpty
              ? Icon(Icons.person, color: cs.onPrimaryContainer, size: 20)
              : null,
        ),
        title: Text(
          username.isEmpty ? 'Unknown' : username,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '$currentStreak',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        onTap: () {},
      ),
    );
  }
}
