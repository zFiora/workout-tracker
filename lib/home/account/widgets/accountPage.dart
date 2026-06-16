import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/account/accountViewModel.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/home/account/widgets/accountPageBody.dart';
import 'package:workout_tracker/home/history/ViewModel/historyViewModel.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/splash/splashLoading.dart';
import 'package:workout_tracker/core/pb.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
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

    if (vm.account == null) {
      if (vm.error != null) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    vm.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: vm.refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final a = vm.account!;
    final streakDays = context.select<HistoryViewModel, int>(
      (vm) => vm.streak.current,
    );
    final isDark = context.select<AppManager, bool>((m) => m.isDark);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: AccountPageBody(
          name: a.displayName,
          email: a.email,
          streakDays: streakDays,
          avatarUrl: a.avatarUrl,
          isDarkMode: isDark,
          onDarkModeChanged: (v) =>
              context.read<AppManager>().toggleDarkMode(v),
          onEditProfile: () {
            // TODO: open profile editor
          },
          onSignOut: () async {
            await context.read<AuthViewModel>().logout();
            await PB.I.clearAuthEverywhere();
            if (!context.mounted) return;
            context.read<AppManager>().setOffline();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SplashPage()),
              (_) => false,
            );
          },
        ),
      ),
    );
  }
}
