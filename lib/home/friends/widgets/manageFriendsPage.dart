// lib/home/account/friends/manage_friends_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
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
            _SectionTitle('Incoming Requests'),
            if (vm.incoming.isEmpty) _EmptyHint('No incoming requests.'),
            ...vm.incoming.map((r) => _IncomingTile(record: r)),

            const SizedBox(height: 16),
            _SectionTitle('Outgoing Requests'),
            if (vm.outgoing.isEmpty) _EmptyHint('No outgoing requests.'),
            ...vm.outgoing.map((r) => _OutgoingTile(record: r)),
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
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
  const _IncomingTile({required this.record});
  final RecordModel record;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<FriendsViewModel>();
    final from = record.get<RecordModel?>('expand.fromUser');

    final name = from?.getStringValue('username') ?? from?.id ?? 'Unknown';

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.mail)),
      title: Text(name),
      subtitle: const Text('wants to be your friend'),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => vm.accept(record.id),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => vm.decline(record.id),
          ),
        ],
      ),
    );
  }
}

class _OutgoingTile extends StatelessWidget {
  const _OutgoingTile({required this.record});
  final RecordModel record;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<FriendsViewModel>();
    final to = record.get<RecordModel?>('expand.toUser');
    final name = to?.getStringValue('username') ?? to?.id ?? 'Unknown';

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.send)),
      title: Text(name),
      subtitle: const Text('pending'),
      trailing: IconButton(
        icon: const Icon(Icons.cancel_outlined),
        onPressed: () => vm.cancel(record.id),
      ),
    );
  }
}
