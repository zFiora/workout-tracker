import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';

class GradientPillButton extends StatelessWidget {
  const GradientPillButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context).size.width - 48; // 24 padding each side
    const height = 56.0;
    final radius = BorderRadius.circular(28);

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF0B4DD7),
              Color(0xFF0A2D73),
            ], // adjust to match Figma
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: MyCustomButton(
          type: CustomButtonType.elevated, // white text in your widget
          label: label,
          onPressed: onPressed,
          isLoading: loading,
          padding: EdgeInsets.zero, // exact height
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
            shadowColor: WidgetStateProperty.all(Colors.transparent),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: radius),
            ),
            fixedSize: WidgetStateProperty.all(const Size.fromHeight(height)),
          ),
        ),
      ),
    );
  }
}
