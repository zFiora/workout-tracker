// ignore_for_file: file_names

import 'package:flutter/material.dart';

enum CustomButtonType { text, elevated, outlined }

enum IconPosition { left, right }

class MyCustomButton extends StatelessWidget {
  const MyCustomButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.type = CustomButtonType.elevated,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.icon,
    this.iconPosition = IconPosition.left,
    this.fullWidth = false,
    this.isLoading = false,
    this.style,
    this.width,
    this.height,
    this.labelColor,
  });

  final VoidCallback? onPressed;
  final String label;
  final CustomButtonType type;
  final EdgeInsets padding;
  final IconData? icon;
  final IconPosition iconPosition;
  final bool fullWidth;
  final bool isLoading;
  final double? width;
  final double? height;
  final ButtonStyle? style;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = _getTextColor(type, primaryColor);

    final child = Padding(
      padding: padding,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null && iconPosition == IconPosition.left) ...[
                  Icon(icon, size: 20, color: textColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: labelColor ?? textColor,
                  ),
                ),
                if (icon != null && iconPosition == IconPosition.right) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 20, color: textColor),
                ],
              ],
            ),
    );

    Widget button;
    switch (type) {
      case CustomButtonType.text:
        button = TextButton(
          onPressed: _effectiveOnPressed,
          style: style,
          child: child,
        );
        break;
      case CustomButtonType.elevated:
        button = ElevatedButton(
          onPressed: _effectiveOnPressed,
          style: style,
          child: child,
        );
        break;
      case CustomButtonType.outlined:
        button = OutlinedButton(
          onPressed: _effectiveOnPressed,
          style: style,
          child: child,
        );
        break;
    }

    return SizedBox(
      width: fullWidth ? double.infinity : width?.toDouble(),
      height: height?.toDouble(),
      child: button,
    );
  }

  VoidCallback? get _effectiveOnPressed => isLoading ? null : onPressed;

  Color _getTextColor(CustomButtonType type, Color primary) {
    switch (type) {
      case CustomButtonType.text:
      case CustomButtonType.outlined:
        return primary;
      case CustomButtonType.elevated:
        return Colors.white;
    }
  }
}
