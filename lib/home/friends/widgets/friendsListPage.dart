import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No friends yet.\nTap “Add Friends” from Account to get started.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ...vm.friends.map((u) => _FriendTile(user: u)),
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.user});
  final RecordModel user;

  @override
  Widget build(BuildContext context) {
    final username = user.getStringValue('name');
    final currentStreak = user.getIntValue('currentStreak');
    final image = user.get('avatar');
    print(image);
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(image)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orangeAccent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 16,
              color: Colors.white,
            ),
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
      title: Text(username),
      onTap: () {}, // TODO: open friend profile/activity
    );
  }
}
