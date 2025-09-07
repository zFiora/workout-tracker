import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
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
    final username = user.getStringValue('username');
    final email = user.getStringValue('email');
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(username),
      subtitle: Text(email),
      onTap: () {}, // TODO: open friend profile/activity
    );
  }
}
