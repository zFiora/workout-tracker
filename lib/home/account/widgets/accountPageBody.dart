import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/tutorial/tutorial_runner.dart';
import 'package:workout_tracker/common/units/weight_unit.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:workout_tracker/home/session/rest_timer_manager.dart';
import 'package:workout_tracker/home/account/widgets/accountPageDangerTile.dart';
import 'package:workout_tracker/home/account/widgets/accountPageHeader.dart';
import 'package:workout_tracker/home/account/widgets/accountPageSection.dart';
import 'package:workout_tracker/home/account/widgets/accountPageSwitchTile.dart';
import 'package:workout_tracker/home/account/widgets/accountPageTile.dart';
import 'package:workout_tracker/home/account/widgets/personalDetailsSheet.dart';
import 'package:workout_tracker/home/account/widgets/profileStatsGrid.dart';
import 'package:workout_tracker/home/friends/widgets/addFriendPage.dart';
import 'package:workout_tracker/home/friends/widgets/friendsListPage.dart';
import 'package:workout_tracker/home/friends/widgets/manageFriendsPage.dart';
import 'package:workout_tracker/home/social/pages/leaderboard_page.dart';
import 'package:workout_tracker/home/support/services/device_context.dart';
import 'package:workout_tracker/home/support/widgets/my_bug_reports_page.dart';
import 'package:workout_tracker/home/support/widgets/report_bug_page.dart';

/// Small, honest placeholder for a feature that isn't implemented yet — a
/// silent no-op `onTap` looks broken (nothing visibly happens), which reads
/// worse than admitting the feature isn't there yet.
void _notYetAvailable(BuildContext context) {
  Mycustomsnackbar.show(context, message: 'Coming soon');
}

Future<void> _showRestPicker(BuildContext context) async {
  final rest = context.read<RestTimerManager>();
  const options = [60, 90, 120, 150, 180, 240]; // seconds
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in options)
            RadioListTile<int>(
              value: s,
              groupValue: rest.defaultSeconds,
              onChanged: (v) {
                if (v != null) rest.setDefaultSeconds(v);
                Navigator.pop(sheetCtx);
              },
              title: Text(s % 60 == 0 ? '${s ~/ 60} min' : '${s ~/ 60} min ${s % 60}s'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _showUnitPicker(BuildContext context) async {
  final app = context.read<AppManager>();
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final u in WeightUnit.values)
            RadioListTile<WeightUnit>(
              value: u,
              groupValue: app.weightUnit,
              onChanged: (v) {
                if (v != null) app.setWeightUnit(v);
                Navigator.pop(sheetCtx);
              },
              title: Text(u == WeightUnit.kg ? 'Kilograms (kg)' : 'Pounds (lb)'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class AccountPageBody extends StatefulWidget {
  const AccountPageBody({
    super.key,
    required this.name,
    required this.username,
    required this.email,
    required this.streakCurrent,
    required this.streakBest,
    required this.avatarBase64,
    required this.onEditProfile,
    required this.onEditAvatar,
    required this.onChangePassword,
    required this.onSignOut,
    required this.onDeleteAccount,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final String name;
  final String username;
  final String email;
  final int streakCurrent;
  final int streakBest;
  final String? avatarBase64;
  final VoidCallback onEditProfile;
  final VoidCallback onEditAvatar;
  final VoidCallback onChangePassword;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<AccountPageBody> createState() => _AccountPageBodyState();
}

class _AccountPageBodyState extends State<AccountPageBody> {
  final _leaderboardKey = GlobalKey();
  final _friendsKey = GlobalKey();
  final _addFriendsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    TutorialRunner.schedule(
      context,
      id: Tutorials.social,
      steps: () => [
        CoachMarkStep(
          targetKey: _leaderboardKey,
          title: 'Streak leaderboard',
          description:
              'See how your workout streak ranks against your friends\' and '
              'keep each other accountable.',
        ),
        CoachMarkStep(
          targetKey: _friendsKey,
          title: 'Your friends',
          description:
              'View your friends, their streaks and their shared workout '
              'templates.',
        ),
        CoachMarkStep(
          targetKey: _addFriendsKey,
          title: 'Add friends',
          description:
              'Search people by username to send a friend request and start '
              'comparing progress.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Aliases so the existing markup below reads unchanged after the
    // stateless→stateful conversion.
    final name = widget.name;
    final username = widget.username;
    final email = widget.email;
    final streakCurrent = widget.streakCurrent;
    final streakBest = widget.streakBest;
    final avatarBase64 = widget.avatarBase64;
    final onEditProfile = widget.onEditProfile;
    final onEditAvatar = widget.onEditAvatar;
    final onChangePassword = widget.onChangePassword;
    final onSignOut = widget.onSignOut;
    final onDeleteAccount = widget.onDeleteAccount;
    final isDarkMode = widget.isDarkMode;
    final onDarkModeChanged = widget.onDarkModeChanged;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AccountPageHeader(
            name: name,
            username: username,
            email: email,
            avatarBase64: avatarBase64,
            onEditProfile: onEditProfile,
            onEditAvatar: onEditAvatar,
          ),
        ),

        // Real, computed workout stats (nothing fabricated).
        SliverToBoxAdapter(
          child: ProfileStatsGrid(
            currentStreak: streakCurrent,
            bestStreak: streakBest,
          ),
        ),

        // ACCOUNT
        SliverToBoxAdapter(
          child: AccountPageSection(
            title: 'Account',
            children: [
              AccountPageTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Name & username',
                onTap: onEditProfile,
              ),
              AccountPageTile(
                icon: Icons.badge_outlined,
                title: 'Personal Details',
                subtitle: 'Sex & date of birth',
                onTap: () => PersonalDetailsSheet.show(context),
              ),
              AccountPageTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: onChangePassword,
              ),
            ],
          ),
        ),

        // SOCIAL
        SliverToBoxAdapter(
          child: AccountPageSection(
            title: 'Social',
            children: [
              KeyedSubtree(
                key: _leaderboardKey,
                child: AccountPageTile(
                  icon: Icons.emoji_events_outlined,
                  title: 'Leaderboard',
                  subtitle: 'Streak rankings with friends',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                  ),
                ),
              ),
              KeyedSubtree(
                key: _friendsKey,
                child: AccountPageTile(
                  icon: Icons.group_outlined,
                  title: 'Friends',
                  subtitle: 'Your friends & activity',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FriendsListPage()),
                  ),
                ),
              ),
              KeyedSubtree(
                key: _addFriendsKey,
                child: AccountPageTile(
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Add Friends',
                  subtitle: 'Search by username',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddFriendPage()),
                  ),
                ),
              ),
              AccountPageTile(
                icon: Icons.manage_accounts_outlined,
                title: 'Manage Friends',
                subtitle: 'Requests & pending',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageFriendsPage()),
                ),
              ),
            ],
          ),
        ),

        // PREFERENCES
        SliverToBoxAdapter(
          child: AccountPageSection(
            title: 'Preferences',
            children: [
              AccountPageSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                initialValue: isDarkMode,
                onChanged: onDarkModeChanged,
              ),
              Builder(
                builder: (ctx) {
                  final unit = ctx.select<AppManager, WeightUnit>(
                    (m) => m.weightUnit,
                  );
                  return AccountPageTile(
                    icon: Icons.scale_outlined,
                    title: 'Units',
                    subtitle:
                        unit == WeightUnit.kg ? 'Kilograms (kg)' : 'Pounds (lb)',
                    onTap: () => _showUnitPicker(ctx),
                  );
                },
              ),
              Builder(
                builder: (ctx) {
                  final secs = ctx.select<RestTimerManager, int>(
                    (m) => m.defaultSeconds,
                  );
                  final m = secs ~/ 60;
                  final s = secs % 60;
                  final label = s == 0 ? '${m}m' : '${m}m ${s}s';
                  return AccountPageTile(
                    icon: Icons.timer_outlined,
                    title: 'Default rest',
                    subtitle: 'Auto-starts after each set · $label',
                    onTap: () => _showRestPicker(ctx),
                  );
                },
              ),
              Builder(
                builder: (ctx) {
                  final enabled = ctx.select<RestTimerManager, bool>(
                    (m) => m.notificationsEnabled,
                  );
                  return AccountPageSwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Rest Timer Notifications',
                    subtitle:
                        'Show the rest timer and completion notification while '
                        'the app is in the background.',
                    initialValue: enabled,
                    onChanged: (v) =>
                        ctx.read<RestTimerManager>().setNotificationsEnabled(v),
                  );
                },
              ),
            ],
          ),
        ),

        // SUPPORT
        SliverToBoxAdapter(
          child: AccountPageSection(
            title: 'Support',
            children: [
              AccountPageTile(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                subtitle: 'Tell us what went wrong',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ReportBugPage()),
                ),
              ),
              AccountPageTile(
                icon: Icons.fact_check_outlined,
                title: 'My Bug Reports',
                subtitle: 'Track reports you\'ve submitted',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MyBugReportsPage()),
                ),
              ),
            ],
          ),
        ),

        // DATA
        SliverToBoxAdapter(
          child: AccountPageSection(
            title: 'Data',
            children: [
              AccountPageTile(
                icon: Icons.cloud_download_outlined,
                title: 'Export Data',
                subtitle: 'Download your workouts',
                onTap: () => _notYetAvailable(context),
              ),
            ],
          ),
        ),

        // DANGER ZONE
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AccountPageDangerTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  onTap: onSignOut,
                ),
                const SizedBox(height: 10),
                AccountPageDangerTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete account',
                  onTap: onDeleteAccount,
                ),
                if (DeviceContext.appVersion != null) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'v${DeviceContext.appVersion}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
