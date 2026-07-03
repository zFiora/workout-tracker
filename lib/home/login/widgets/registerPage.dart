import 'dart:io';
import 'package:flutter/material.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/navigation/mainNavigation.dart';
import 'package:workout_tracker/common/widgets/avatarPicker.dart';
import 'package:workout_tracker/home/account/accountReposirtry.dart';
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

  File? _avatarFile;

  // Form controllers
  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
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
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final bool keyboardOpen = viewInsets > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false, // important: let us control resize
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.midnight,
            ),
          ),

          // Hero image
          Positioned(
            left: -12,
            top: MediaQuery.of(context).padding.top + 8,
            width: size.width * 0.72,
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

          // Title
          Positioned(
            right: 24,
            top: MediaQuery.of(context).padding.top + 12,
            child: Text(
              'Gym Tracker',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _sheetSlide,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: keyboardOpen ? size.height : size.height * 0.58,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.7),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 24,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    keyboardOpen ? 16 : 28,
                    24,
                    20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(bottom: viewInsets + 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Center(
                            child: Transform.translate(
                              offset: const Offset(0, -12),
                              child: AvatarPicker(
                                size: 96,
                                placeholderAsset:
                                    'assets/logo/default_avatar.png',
                                onChanged: (f) =>
                                    setState(() => _avatarFile = f),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          UnderlineField(
                            label: 'Display Name',
                            hint: 'John Doe',
                            controller: _displayNameCtrl,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Display name is required'
                                : null,
                          ),

                          const SizedBox(height: 14),
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
                              if (v == null || v.trim().isEmpty)
                                return 'Email is required';
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
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    // Capture before any await
                                    final appManager =
                                        context.read<AppManager>();
                                    final authVM =
                                        context.read<AuthViewModel>();
                                    final accountRepo =
                                        context.read<AccountRepository>();
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final nav = Navigator.of(context);
                                    final avatarFile = _avatarFile;

                                    final ok = await authVM.register(
                                      email: _emailCtrl.text.trim(),
                                      username: _usernameCtrl.text.trim(),
                                      password: _passCtrl.text,
                                      displayName:
                                          _displayNameCtrl.text.trim(),
                                    );
                                    if (!mounted) return;

                                    if (ok) {
                                      // Best-effort avatar upload
                                      if (avatarFile != null) {
                                        try {
                                          await accountRepo
                                              .uploadAvatar(avatarFile);
                                        } catch (_) {}
                                      }
                                      appManager.setOnline();
                                      nav.pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const MainNavigation(),
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            authVM.error ??
                                                'Registration failed',
                                          ),
                                        ),
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
                                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
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
        ],
      ),
    );
  }
}
