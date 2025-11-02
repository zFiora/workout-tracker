// lib/home/account/friends/add_friend_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/friends/friendsViewModel.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});
  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final _query = TextEditingController();
  bool _searching = false;

  Future<void> _doSearch(FriendsViewModel vm) async {
    setState(() => _searching = true);
    await vm.search(_query.text);
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsViewModel>();
    return MyCustomeScaffoldView(
      title: 'Add Friend',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _query,
                  decoration: const InputDecoration(
                    hintText: 'Search username or email',
                  ),
                  onSubmitted: (_) => _doSearch(vm),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _doSearch(vm),
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_searching) const Center(child: CircularProgressIndicator()),
          ...vm.searchResults.map(
            (u) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(u.getStringValue('username')),
              subtitle: Text(u.getStringValue('email')),
              trailing: TextButton(
                onPressed: () async {
                  await vm.send(u.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request sent')),
                    );
                  }
                }, 
                child: const Text('Add'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
