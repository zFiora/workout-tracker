import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/friends/friendModel.dart';
import 'package:workout_tracker/home/friends/friendsViewModel.dart';

class ManageFriendsPage extends StatefulWidget {
  const ManageFriendsPage({super.key});
  @override
  State<ManageFriendsPage> createState() => _ManageFriendsPageState();
}

class _ManageFriendsPageState extends State<ManageFriendsPage> {
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
      title: 'Manage Friends',
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
            const _SectionTitle('Incoming Requests'),
            if (vm.incoming.isEmpty) const _EmptyHint('No incoming requests.'),
            ...vm.incoming.map((r) => _IncomingTile(request: r)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text));
}

class _IncomingTile extends StatelessWidget {
  const _IncomingTile({required this.request});
  final PendingRequest request;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<FriendsViewModel>();
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.mail)),
      title: Text(request.requester.name),
      subtitle: Text('@${request.requester.username}'),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => vm.accept(request.friendshipId),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => vm.decline(request.friendshipId),
          ),
        ],
      ),
    );
  }
}
