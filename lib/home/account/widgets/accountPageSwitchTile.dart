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
    const kDeepBlue = Color(0xFF0A2D73);
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
          // ignore: deprecated_member_use
          backgroundColor: scheme.primary.withOpacity(.08),
          child: Icon(widget.icon, color: kDeepBlue, size: 20),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
