import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/account/accountViewModel.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/home/account/widgets/accountPageBody.dart';
import 'package:workout_tracker/home/login/widgets/loginPage.dart';

/// Brand blues
const kPrimaryBlue = Color(0xFF0B4DD7);
const kDeepBlue = Color(0xFF0A2D73);

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountViewModel>();

    if (vm.account == null && !vm.loading && vm.error == null) {
      Future.microtask(() => context.read<AccountViewModel>().load());
    }

    // Loading / first paint
    if (vm.loading && vm.account == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Error state
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

    final int streakDays = 0;

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
            // TODO: open edit bottom sheet / page, then call:
            // context.read<AccountViewModel>().update(displayName: ..., username: ..., avatarFile: ...);
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
