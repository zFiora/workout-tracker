import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/account/accountViewModel.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/home/account/widgets/accountPageBody.dart';
import 'package:workout_tracker/home/history/historyViewModel.dart';
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
    // Trigger load after first frame
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

    // 1) If we have no account yet, show loader or error
    if (vm.account == null) {
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
      // initial frame OR loading → show spinner
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2) We have data; render page
    final a = vm.account!;
    final streakDays = context.select<HistoryViewModel, int>(
      (vm) => vm.streak.current,
    );

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
            // open editor and call vm.update(...)
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
