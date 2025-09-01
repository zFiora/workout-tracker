import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/common/navigation/mainNavigation.dart';
import 'package:workout_tracker/home/login/widgets/gradiantPillButton.dart';
import 'package:workout_tracker/home/login/widgets/registerPage.dart';
import 'package:workout_tracker/home/login/widgets/underlineField.dart';

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

  // image slide from the left
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
        clipBehavior: Clip.none,
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
                            UnderlineField(
                              label: 'Email or Username',
                              hint: 'your@email.com  or  username123',
                              controller: _idCtrl,
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            UnderlineField(
                              label: 'Password',
                              controller: _passCtrl,
                              obscure: _obscure,
                              onToggleObscure: () =>
                                  setState(() => _obscure = !_obscure),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                if (v.length < 6) return 'Minimum 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),

                            // Gradient pill SIGN IN
                            GradientPillButton(
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
