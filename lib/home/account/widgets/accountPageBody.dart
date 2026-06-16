import 'package:flutter/material.dart';
import 'package:workout_tracker/home/account/widgets/accountPageDangerTile.dart';
import 'package:workout_tracker/home/account/widgets/accountPageHeader.dart';
import 'package:workout_tracker/home/account/widgets/accountPageSection.dart';
import 'package:workout_tracker/home/account/widgets/accountPageSwitchTile.dart';
import 'package:workout_tracker/home/account/widgets/accountPageTile.dart';
import 'package:workout_tracker/home/account/widgets/accountPageVaultTile.dart';
import 'package:workout_tracker/home/friends/widgets/addFriendPage.dart';
import 'package:workout_tracker/home/friends/widgets/friendsListPage.dart';
import 'package:workout_tracker/home/friends/widgets/manageFriendsPage.dart';
import 'package:workout_tracker/home/social/pages/leaderboard_page.dart';

class AccountPageBody extends StatelessWidget {
  const AccountPageBody({
    super.key,
    required this.name,
    required this.email,
    required this.streakDays,
    required this.avatarUrl,
    required this.onEditProfile,
    required this.onSignOut,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final String name;
  final String email;
  final int streakDays;
  final String? avatarUrl;
  final VoidCallback onEditProfile;
  final VoidCallback onSignOut;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AccountPageHeader(
            name: name,
            email: email,
            streakDays: streakDays,
            avatarUrl: avatarUrl,
            onEditProfile: onEditProfile,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 60)),

        // Friends section
        SliverToBoxAdapter(
          child: AccountPageSection(
            title: 'Social',
            children: [
              AccountPageVaultTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orangeAccent,
                title: 'Streak',
                value: '$streakDays days',
                onTap: () {},
              ),
              AccountPageTile(
                icon: Icons.emoji_events_outlined,
                title: 'Leaderboard',
                subtitle: 'Streak rankings with friends',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                ),
              ),
              AccountPageTile(
                icon: Icons.group_outlined,
                title: 'Friends',
                subtitle: 'Your friends & activity',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FriendsListPage()),
                ),
              ),
              AccountPageTile(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Add Friends',
                subtitle: 'Search by username or QR',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddFriendPage()),
                ),
              ),
              AccountPageTile(
                icon: Icons.manage_accounts_outlined,
                title: 'Manage Friends',
                subtitle: 'Requests · Blocks · Visibility',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageFriendsPage()),
                ),
              ),
            ],
          ),
        ),

        // Account section
        SliverToBoxAdapter(
          child: AccountPageSection(
            title: 'Account',
            children: [
              AccountPageTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Name, photo, email',
                onTap: onEditProfile,
              ),
              AccountPageTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {},
              ),
            ],
          ),
        ),

        // App section
        SliverToBoxAdapter(
          child: AccountPageSection(
            title: 'App',
            children: [
              AccountPageTile(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                subtitle: 'Reminders & workout alerts',
                onTap: () {},
              ),
              AccountPageSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                initialValue: isDarkMode,
                onChanged: onDarkModeChanged,
              ),
              AccountPageTile(
                icon: Icons.verified_user_outlined,
                title: 'Privacy & Data',
                onTap: () {},
              ),
              AccountPageTile(
                icon: Icons.cloud_download_outlined,
                title: 'Export Data',
                onTap: () {},
              ),
            ],
          ),
        ),

        // Help + Danger
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              children: [
                AccountPageSection(
                  title: 'Help',
                  children: [
                    AccountPageTile(
                      icon: Icons.help_outline,
                      title: 'FAQ & Support',
                      onTap: () {},
                    ),
                    AccountPageTile(
                      icon: Icons.star_border_rounded,
                      title: 'Rate the App',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AccountPageDangerTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  onTap: onSignOut,
                ),
                const SizedBox(height: 24),
                Text(
                  'v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
