// lib/auth/register_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/common/navigation/mainNavigation.dart';
import 'package:workout_tracker/home/login/widgets/gradiantPillButton.dart';
import 'package:workout_tracker/home/login/widgets/loginPage.dart';
import 'package:workout_tracker/home/login/widgets/underlineField.dart';

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
                            UnderlineField(
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
                            UnderlineField(
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
                            UnderlineField(
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
                            UnderlineField(
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
                            GradientPillButton(
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
