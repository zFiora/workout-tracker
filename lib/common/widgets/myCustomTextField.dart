import 'package:flutter/material.dart';

/// Rounded filled text field that follows the app's input theme.
class MyCustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData? icon;
  final Function(String)? onChanged;

  const MyCustomTextField({
    super.key,
    this.controller,
    required this.hint,
    this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: icon != null
              ? Icon(icon, size: 20, color: cs.onSurfaceVariant)
              : null,
          hintText: hint,
        ),
      ),
    );
  }
}
