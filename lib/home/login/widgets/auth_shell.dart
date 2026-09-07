import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';

/// Shared chrome for every authentication screen (login, register, forgot /
/// reset password) so they read as one cohesive, branded flow: the midnight
/// gradient, a keyboard-aware scroll, an optional back affordance, and
/// consistent spacing. Screens supply their own [children].
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children, this.onBack});

  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.midnight),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (onBack != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: onBack,
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white),
                            ),
                          )
                        else
                          const SizedBox(height: 4),
                        ...children,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The app wordmark: a volt-tinted glyph tile + "Gym Tracker". Consistent
/// across auth screens so the brand always anchors the top.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.volt.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.volt.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.fitness_center_rounded,
              color: AppColors.volt, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'Gym Tracker',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Colors.white, letterSpacing: 0.4),
        ),
      ],
    );
  }
}

/// Screen headline + supporting line, in the auth type scale.
class AuthHeadline extends StatelessWidget {
  const AuthHeadline({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textMid, height: 1.4),
        ),
      ],
    );
  }
}

/// Inline, field-adjacent error (replaces ugly generic auth SnackBars).
class AuthInlineError extends StatelessWidget {
  const AuthInlineError(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom "already have / don't have an account" switch row.
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.leading,
    required this.action,
    required this.onTap,
  });

  final String leading;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            leading,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
