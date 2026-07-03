import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';

class GradientPillButton extends StatelessWidget {
  const GradientPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.whiteColor = false,
    this.labelColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool whiteColor;
  final Color? labelColor;

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
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: whiteColor
                ? [
                    Color.fromARGB(255, 255, 255, 255),
                    Color.fromARGB(172, 172, 170, 170),
                  ]
                : [AppColors.volt, AppColors.voltDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.voltDeep.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: MyCustomButton(
          labelColor: labelColor,
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
