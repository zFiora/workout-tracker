import 'package:flutter/material.dart';

class AccountPageSwitchTile extends StatefulWidget {
  const AccountPageSwitchTile({
    super.key,
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
  State<AccountPageSwitchTile> createState() => _AccountPageSwitchTileState();
}

class _AccountPageSwitchTileState extends State<AccountPageSwitchTile> {
  late bool value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: (v) {
          setState(() => value = v);
          widget.onChanged(v);
        },
        title: Text(widget.title),
        secondary: CircleAvatar(
          radius: 18,
          // ignore: deprecated_member_use
          backgroundColor: scheme.primary.withValues(alpha: .08),
          child: Icon(widget.icon, color: scheme.primary, size: 20),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
