// lib/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/common/navigation/mainNavigation.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/home/login/widgets/registerPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  // Hero slides in from the left (same feel as Register)
  late final Animation<Offset> _charSlide =
      Tween<Offset>(begin: const Offset(-0.25, 0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _ac,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        ),
      );

  // Sheet pulls up from bottom
  late final Animation<Offset> _sheetSlide =
      Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _ac,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
        ),
      );

  // Form
  final _idCtrl = TextEditingController(); // email OR username
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom; // keyboard

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none, // allow hero to overlap sheet
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2B66), Color(0xFF0F172A)],
              ),
            ),
          ),

          // 2) HERO — painted first so it sits UNDER the sheet
          Positioned(
            left: -12,
            top: MediaQuery.of(context).padding.top + 8,
            width: MediaQuery.of(context).size.width * 0.72,
            child: SlideTransition(
              position: _charSlide,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/logo/login_image.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // 3) SHEET — painted after hero, so it’s ON TOP
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _sheetSlide,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: viewInsets),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: size.height * 0.58),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _UnderlineField(
                              label: 'Email or Username',
                              hint: 'your@email.com  or  gym_repear',
                              controller: _idCtrl,
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _UnderlineField(
                              label: 'Password',
                              controller: _passCtrl,
                              obscure: _obscure,
                              onToggleObscure: () =>
                                  setState(() => _obscure = !_obscure),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Password is required';
                                if (v.length < 6) return 'Minimum 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),

                            // Gradient pill SIGN IN
                            _GradientPillButton(
                              label: 'SIGN IN',
                              loading: vm.busy,
                              onPressed: vm.busy
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate())
                                        return;
                                      final ok = await context
                                          .read<AuthViewModel>()
                                          .login(
                                            _idCtrl.text.trim(),
                                            _passCtrl.text,
                                          );
                                      if (!mounted) return;
                                      if (ok) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const MainNavigation(),
                                          ),
                                        );
                                      } else {
                                        final msg =
                                            context
                                                .read<AuthViewModel>()
                                                .error ??
                                            'Login failed';
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(msg)),
                                        );
                                      }
                                    },
                            ),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.black54),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterPage(),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign Up',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Title on the right
          Positioned(
            right: 24,
            top: MediaQuery.of(context).padding.top + 12,
            child: Text(
              'Gym Tracker',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// --- Shared bits (same as in Register) ---

class _UnderlineField extends StatelessWidget {
  const _UnderlineField({
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.onToggleObscure,
    this.validator,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            border: const UnderlineInputBorder(),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primary, width: 2),
            ),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _GradientPillButton extends StatelessWidget {
  const _GradientPillButton({
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
