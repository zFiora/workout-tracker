import 'package:flutter/material.dart';

class AccountPageVaultTile extends StatelessWidget {
  const AccountPageVaultTile({
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
    const kDeepBlue = Color(0xFF0A2D73);

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
