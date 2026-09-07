import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/navigation/mainNavigation.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/home/login/widgets/auth_shell.dart';
import 'package:workout_tracker/home/login/widgets/forgotPasswordPage.dart';
import 'package:workout_tracker/home/login/widgets/gradiantPillButton.dart';
import 'package:workout_tracker/home/login/widgets/registerPage.dart';
import 'package:workout_tracker/home/login/widgets/underlineField.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idCtrl = TextEditingController(); // email OR username
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final appManager = context.read<AppManager>();
    final authVM = context.read<AuthViewModel>();
    final ok = await authVM.login(_idCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;

    if (ok) {
      appManager.setOnline();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      // Inline error, next to the form — not a transient SnackBar.
      setState(() => _error = authVM.error ?? 'Login failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthViewModel, bool>((m) => m.busy);

    return AuthScaffold(
      children: [
        const SizedBox(height: 8),
        const AuthBrandHeader(),
        const SizedBox(height: 36),
        const AuthHeadline(
          title: 'Welcome back',
          subtitle: 'Sign in to pick up where you left off.',
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UnderlineField(
                label: 'Email or Username',
                hint: 'your@email.com',
                controller: _idCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 18),
              UnderlineField(
                label: 'Password',
                hint: '••••••••',
                controller: _passCtrl,
                obscure: _obscure,
                textInputAction: TextInputAction.done,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                // Login only checks presence — enforcing the current minimum
                // length here would lock out valid legacy passwords.
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password is required' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.volt),
            child: const Text('Forgot Password?',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          AuthInlineError(_error!),
        ],
        const SizedBox(height: 20),
        Center(
          child: GradientPillButton(
            label: 'SIGN IN',
            loading: busy,
            onPressed: busy ? null : _submit,
          ),
        ),
        const SizedBox(height: 20),
        AuthSwitchPrompt(
          leading: "Don't have an account?",
          action: 'Sign Up',
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RegisterPage()),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
