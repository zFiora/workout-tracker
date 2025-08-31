// lib/auth/register_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/auth/authViewModel.dart'; // keep same path you used in Splash
import 'package:workout_tracker/common/navigation/mainNavigation.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/home/login/widgets/loginPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  // Character slides in from left
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

  // Form controllers
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final viewInsets = MediaQuery.of(context).viewInsets.bottom; // keyboard

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2B66), Color(0xFF0F172A)],
              ),
            ),
          ),
          // 1) Background stays first
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2B66), Color(0xFF0F172A)],
              ),
            ),
          ),

          // 2) Sliding sheet (keep your existing block here)
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _sheetSlide,
              // ... your sheet Container ...
            ),
          ),

          // 3) BIG character, left-aligned, overlapping the sheet
          Positioned(
            left: -12, // a tiny negative to “hug” the edge
            top: MediaQuery.of(context).padding.top + 8,
            width: MediaQuery.of(context).size.width * 0.72, // make it big
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

          // 4) Title on the right, clear of the hero
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

          // Sliding sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _sheetSlide,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: viewInsets,
                ), // lift on keyboard
                child: Container(
                  width: double.infinity,
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
                              label: 'Username',
                              hint: 'Gym Repear',
                              controller: _usernameCtrl,
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Username is required'
                                  : (v.trim().length < 3
                                        ? 'Min 3 characters'
                                        : null),
                            ),
                            const SizedBox(height: 14),
                            _UnderlineField(
                              label: 'Email',
                              hint: 'john@email.com',
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!v.contains('@'))
                                  return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _UnderlineField(
                              label: 'Password',
                              controller: _passCtrl,
                              obscure: _obscure1,
                              textInputAction: TextInputAction.next,
                              onToggleObscure: () =>
                                  setState(() => _obscure1 = !_obscure1),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Password is required';
                                if (v.length < 8) return 'Min 8 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _UnderlineField(
                              label: 'Confirm Password',
                              controller: _confirmCtrl,
                              obscure: _obscure2,
                              onToggleObscure: () =>
                                  setState(() => _obscure2 = !_obscure2),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Confirm your password';
                                if (v != _passCtrl.text)
                                  return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),

                            // Gradient pill "SIGN UP"
                            _GradientPillButton(
                              label: 'SIGN UP',
                              loading: vm.busy,
                              onPressed: vm.busy
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate())
                                        return;
                                      final ok = await context
                                          .read<AuthViewModel>()
                                          .register(
                                            email: _emailCtrl.text.trim(),
                                            username: _usernameCtrl.text.trim(),
                                            password: _passCtrl.text,
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
                                            'Registration failed';
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
                                  'Already signed up? ',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.black54),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign In',
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
        ],
      ),
    );
  }
}

/// Simple underline text field that matches your design.
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

/// Uses your MyCustomeButton to keep behavior consistent, but wraps it
/// in a gradient pill container to match the Figma look.
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
            ], // tweak to your exact hexes
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
          // Your button picks text color based on type; elevated => white text.
          type: CustomButtonType.elevated,
          label: label,
          onPressed: onPressed,
          isLoading: loading,
          padding: EdgeInsets.zero, // keep exact height
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
            shadowColor: WidgetStateProperty.all(Colors.transparent),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: radius),
            ),
            fixedSize: WidgetStateProperty.all(const Size.fromHeight(height)),
          ),
          // If your class has width/height properties now, you can pass them too.
          // width: width,
          // height: height,
        ),
      ),
    );
  }
}
