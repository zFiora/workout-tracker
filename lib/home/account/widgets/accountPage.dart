import 'package:flutter/material.dart';
// If you have this scaffold, use it (uncomment next line and swap Scaffold below).
// import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';

/// Your brand blues
const kPrimaryBlue = Color(0xFF0B4DD7);
const kDeepBlue = Color(0xFF0A2D73);

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    this.name = 'Haidar AlDahan',
    this.email = 'haidar@example.com',
    this.streakDays = 5,
  });

  final String name;
  final String email;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // If you prefer your custom scaffold:
    // return MyCustomeScaffoldView(
    //   title: 'Account',
    //   body: _Body(name: name, email: email, streakDays: streakDays),
    // );

    return Scaffold(
      backgroundColor: scheme.surface,
      body: _Body(name: name, email: email, streakDays: streakDays),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.name,
    required this.email,
    required this.streakDays,
  });

  final String name;
  final String email;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _Header(
            name: name,
            email: email,
            streakDays: streakDays,
            onEditProfile: () {
              // TODO: push to Edit Profile screen
              // Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
            },
          ),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: 60)),

        // Friends section
        SliverToBoxAdapter(
          child: _Section(
            title: 'Friends',
            children: [
              _ValueTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orangeAccent,
                title: 'Streak',
                value: '$streakDays days',
                onTap: () {
                  // TODO: open streak details
                },
              ),
              _Tile(
                icon: Icons.group_outlined,
                title: 'Friends',
                subtitle: 'Your friends & activity',
                onTap: () {
                  // TODO: open friends list
                },
              ),
              _Tile(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Add Friends',
                subtitle: 'Search by username or QR',
                onTap: () {
                  // TODO: add friend flow
                },
              ),
              _Tile(
                icon: Icons.manage_accounts_outlined,
                title: 'Manage Friends',
                subtitle: 'Requests • Blocks • Visibility',
                onTap: () {
                  // TODO: manage friends
                },
              ),
            ],
          ),
        ),

        // Account section
        SliverToBoxAdapter(
          child: _Section(
            title: 'Account',
            children: [
              _Tile(
                icon: Icons.person_outline,
                title: 'Edit Account',
                subtitle: 'Name, photo, email',
                onTap: () {
                  // TODO: edit account
                },
              ),
              _Tile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  // TODO: password flow
                },
              ),
            ],
          ),
        ),

        // App section
        SliverToBoxAdapter(
          child: _Section(
            title: 'App',
            children: [
              _Tile(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                subtitle: 'Reminders & workout alerts',
                onTap: () {
                  // TODO: open notifications settings
                },
              ),
              _SwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                initialValue: Theme.of(context).brightness == Brightness.dark,
                onChanged: (v) {
                  // TODO: hook into your theme/provider
                },
              ),
              _Tile(
                icon: Icons.verified_user_outlined,
                title: 'Privacy & Data',
                onTap: () {
                  // TODO: privacy screen
                },
              ),
              _Tile(
                icon: Icons.cloud_download_outlined,
                title: 'Export Data',
                onTap: () {
                  // TODO: export user data
                },
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
                _Section(
                  title: 'Help',
                  children: [
                    _Tile(
                      icon: Icons.help_outline,
                      title: 'FAQ & Support',
                      onTap: () {
                        // TODO: help
                      },
                    ),
                    _Tile(
                      icon: Icons.star_border_rounded,
                      title: 'Rate the App',
                      onTap: () {
                        // TODO: open store listing
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _DangerTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  onTap: () async {
                    // TODO: sign out, clear tokens, navigate to login
                  },
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

/// Header with gradient, profile card, and streak badge
class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.email,
    required this.streakDays,
    required this.onEditProfile,
  });

  final String name;
  final String email;
  final int streakDays;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 170,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryBlue, kDeepBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -46,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: scheme.surface,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: scheme.primary.withOpacity(.1),
                        backgroundImage: const AssetImage(
                          // TODO: replace with user photo, or NetworkImage
                          'assets/logo/default_avatar.png',
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 0,
                        ),
                      ),
                      // Streak badge
                      Positioned(
                        right: -4,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$streakDays',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Name + email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit button
                  TextButton.icon(
                    onPressed: onEditProfile,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Text(
                  'Account',
                  style: text.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // Optional settings overflow
                  },
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primary.withOpacity(.08),
          child: Icon(icon, color: kDeepBlue, size: 20),
        ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: (iconColor ?? scheme.primary).withOpacity(.12),
          child: Icon(icon, color: iconColor ?? kDeepBlue, size: 20),
        ),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _SwitchTile extends StatefulWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.initialValue,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  late bool value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: (v) {
          setState(() => value = v);
          widget.onChanged(v);
        },
        title: Text(widget.title),
        secondary: CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primary.withOpacity(.08),
          child: Icon(widget.icon, color: kDeepBlue, size: 20),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.red.withOpacity(.08),
          child: Icon(icon, color: Colors.red, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
