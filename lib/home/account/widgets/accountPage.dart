import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/account/accountViewModel.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/home/account/widgets/accountPageBody.dart';
import 'package:workout_tracker/home/login/widgets/loginPage.dart';

/// Brand blues
const kPrimaryBlue = Color(0xFF0B4DD7);
const kDeepBlue = Color(0xFF0A2D73);

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    // run after the first frame so we don’t trigger setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AccountViewModel>();
      if (vm.account == null && !vm.loading) {
        vm.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountViewModel>();

    // Initial loader
    if (vm.loading && vm.account == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Error UI
    if (vm.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              FilledButton(onPressed: vm.refresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final a = vm.account!;
    const streakDays = 0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: AccountPageBody(
          name: a.displayName,
          email: a.email,
          streakDays: streakDays,
          avatarUrl: a.avatarUrl,
          onEditProfile: () {
            /* open editor and call vm.update(...) */
          },
          onSignOut: () async {
            await context.read<AuthViewModel>().logout();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
        ),
      ),
    );
  }
}
