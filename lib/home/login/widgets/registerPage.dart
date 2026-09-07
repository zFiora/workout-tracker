import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/navigation/mainNavigation.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/validators/password_validator.dart';
import 'package:workout_tracker/common/widgets/avatarPicker.dart';
import 'package:workout_tracker/home/account/accountReposirtry.dart';
import 'package:workout_tracker/home/login/widgets/auth_shell.dart';
import 'package:workout_tracker/home/login/widgets/gradiantPillButton.dart';
import 'package:workout_tracker/home/login/widgets/loginPage.dart';
import 'package:workout_tracker/home/login/widgets/underlineField.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  File? _avatarFile;

  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final appManager = context.read<AppManager>();
    final authVM = context.read<AuthViewModel>();
    final accountRepo = context.read<AccountRepository>();
    final avatarFile = _avatarFile;

    final ok = await authVM.register(
      email: _emailCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      password: _passCtrl.text,
      displayName: _displayNameCtrl.text.trim(),
    );
    if (!mounted) return;

    if (!ok) {
      setState(() =>
          _error = authVM.error ?? 'Registration failed. Please try again.');
      return;
    }

    // Best-effort avatar upload — never blocks account creation.
    if (avatarFile != null) {
      try {
        await accountRepo.uploadAvatar(avatarFile);
      } catch (_) {}
    }
    if (!mounted) return;
    appManager.setOnline();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthViewModel, bool>((m) => m.busy);

    return AuthScaffold(
      onBack: () => Navigator.of(context).maybePop(),
      children: [
        const AuthBrandHeader(),
        const SizedBox(height: 28),
        const AuthHeadline(
          title: 'Create your account',
          subtitle: 'Track workouts, templates and progress — all in one place.',
        ),
        const SizedBox(height: 20),
        Center(
          child: AvatarPicker(
            size: 92,
            placeholderAsset: 'assets/logo/default_avatar.png',
            onChanged: (f) => setState(() => _avatarFile = f),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Add a photo (optional)',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMid),
          ),
        ),
        const SizedBox(height: 18),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UnderlineField(
                label: 'Display Name',
                hint: 'John Doe',
                controller: _displayNameCtrl,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Display name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              UnderlineField(
                label: 'Username',
                hint: 'johndoe',
                controller: _usernameCtrl,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Username is required';
                  if (value.length < 3) return 'Min 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              UnderlineField(
                label: 'Email',
                hint: 'john@email.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Email is required';
                  final ok =
                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
                  if (!ok) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              UnderlineField(
                label: 'Password',
                hint: '••••••••',
                controller: _passCtrl,
                obscure: _obscure1,
                textInputAction: TextInputAction.next,
                onToggleObscure: () => setState(() => _obscure1 = !_obscure1),
                validator: PasswordValidator.validate,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.textMid, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Use at least ${PasswordValidator.minLength} characters.',
                    style: const TextStyle(
                        color: AppColors.textMid, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              UnderlineField(
                label: 'Confirm Password',
                hint: '••••••••',
                controller: _confirmCtrl,
                obscure: _obscure2,
                textInputAction: TextInputAction.done,
                onToggleObscure: () => setState(() => _obscure2 = !_obscure2),
                validator: (v) =>
                    PasswordValidator.validateConfirmation(v, _passCtrl.text),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          AuthInlineError(_error!),
        ],
        const SizedBox(height: 22),
        Center(
          child: GradientPillButton(
            label: 'CREATE ACCOUNT',
            loading: busy,
            onPressed: busy ? null : _submit,
          ),
        ),
        const SizedBox(height: 18),
        AuthSwitchPrompt(
          leading: 'Already have an account?',
          action: 'Sign In',
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
