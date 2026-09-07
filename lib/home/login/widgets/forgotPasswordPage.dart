import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/validators/password_validator.dart';
import 'package:workout_tracker/home/login/widgets/gradiantPillButton.dart';
import 'package:workout_tracker/home/login/widgets/loginPage.dart';
import 'package:workout_tracker/home/login/widgets/underlineField.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Password-recovery flow
//
//  Login → ForgotPasswordScreen → CheckEmailScreen
//                                        │  (user taps the emailed link)
//                                        ▼
//   workouttracker://reset-password?token=…  →  ResetPasswordScreen
//                                                      ▼
//                                              ResetSuccessScreen → Login
//
//  All screens keep the auth visual identity (midnight gradient, white
//  headings) and route only through the existing AuthViewModel — no widget
//  ever touches the network or the token store directly.
// ─────────────────────────────────────────────────────────────────────────────

/// Shared scaffold: midnight-gradient background + a safe, scrollable,
/// keyboard-aware body. Keeps the four screens visually identical without
/// repeating the chrome.
class _AuthGradientScaffold extends StatelessWidget {
  const _AuthGradientScaffold({required this.child, this.onBack});

  final Widget child;
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (onBack != null)
                          IconButton(
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          )
                        else
                          const SizedBox(height: 8),
                        child,
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

Widget _title(BuildContext context, String text) => Text(
      text,
      style:
          Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
    );

Widget _subtitle(BuildContext context, String text) => Text(
      text,
      style:
          Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMid),
    );

Widget _backToLogin(BuildContext context) => Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        ),
        child: const Text('Back to Login'),
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
//  1. Forgot Password — enter email
// ─────────────────────────────────────────────────────────────────────────────

/// Asks for the account email and requests a reset link. Always advances to
/// [CheckEmailScreen] on a non-network success — whether or not the email is
/// registered is deliberately indistinguishable (anti-enumeration).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _networkError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _networkError = null);

    final email = _emailCtrl.text.trim();
    final error = await context.read<AuthViewModel>().requestPasswordReset(email);
    if (!mounted) return;

    // A network/server failure is surfaced; "email not found" is not — it
    // resolves as success and advances to the same confirmation screen.
    if (error != null) {
      setState(() => _networkError = error);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CheckEmailScreen(email: email)),
      );
    }
  }

  /// Back that never traps the user: pop if possible, otherwise (this screen
  /// is the stack root — e.g. reached via "Request a new link") replace with
  /// the login screen.
  void _back() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthViewModel, bool>((m) => m.busy);

    return _AuthGradientScaffold(
      onBack: _back,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _title(context, 'Forgot Password?'),
          const SizedBox(height: 10),
          _subtitle(
            context,
            "Enter the email associated with your account and we'll send you a "
            'password reset link.',
          ),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: UnderlineField(
              label: 'Email',
              hint: 'your@email.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: _validateEmail,
            ),
          ),
          if (_networkError != null) ...[
            const SizedBox(height: 12),
            _ErrorText(_networkError!),
          ],
          const SizedBox(height: 24),
          Center(
            child: GradientPillButton(
              label: 'SEND RESET LINK',
              loading: busy,
              onPressed: busy ? null : _submit,
            ),
          ),
          const SizedBox(height: 12),
          _backToLogin(context),
        ],
      ),
    );
  }
}

/// Basic email validation shared by the recovery screens: required, trimmed,
/// and shaped like an address.
String? _validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Email is required';
  final looksValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  if (!looksValid) return 'Enter a valid email';
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
//  2. Check your email — with resend countdown
// ─────────────────────────────────────────────────────────────────────────────

class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({super.key, required this.email});

  final String email;

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  static const _cooldownSeconds = 60;

  Timer? _timer;
  int _secondsLeft = _cooldownSeconds;
  String? _resendError;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return; // cooldown still active — no-op
    setState(() => _resendError = null);

    final error =
        await context.read<AuthViewModel>().requestPasswordReset(widget.email);
    if (!mounted) return;

    if (error != null) {
      setState(() => _resendError = error);
    } else {
      _startCountdown(); // restart the cooldown on a successful resend
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthViewModel, bool>((m) => m.busy);
    final onCooldown = _secondsLeft > 0;

    return _AuthGradientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.mark_email_read_outlined,
              color: AppColors.volt, size: 56),
          const SizedBox(height: 20),
          _title(context, 'Check Your Email'),
          const SizedBox(height: 10),
          _subtitle(
            context,
            "If an account exists for this email, we've sent you a password "
            'reset link.',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined,
                    color: AppColors.textMid, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_resendError != null) ...[
            const SizedBox(height: 12),
            _ErrorText(_resendError!),
          ],
          const SizedBox(height: 24),
          Center(
            child: GradientPillButton(
              label: onCooldown
                  ? 'RESEND AVAILABLE IN ${_secondsLeft}s'
                  : 'RESEND',
              loading: busy,
              onPressed: (!onCooldown && !busy) ? _resend : null,
            ),
          ),
          const SizedBox(height: 12),
          _backToLogin(context),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  3. Reset password — reached via the deep link (carries the token)
// ─────────────────────────────────────────────────────────────────────────────

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final error = await context.read<AuthViewModel>().confirmPasswordReset(
          token: widget.token,
          newPassword: _passCtrl.text,
        );
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ResetSuccessScreen()),
      );
    } else {
      setState(() => _error = error);
    }
  }

  /// Send the user back to request a fresh link — used when the token is
  /// invalid/expired/used. Replaces the whole stack so they can't navigate
  /// back into the dead reset screen.
  void _requestNewLink() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthViewModel, bool>((m) => m.busy);

    return _AuthGradientScaffold(
      onBack: _requestNewLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _title(context, 'Create New Password'),
          const SizedBox(height: 10),
          _subtitle(
            context,
            'Choose a new password for your account.',
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnderlineField(
                  label: 'New Password',
                  controller: _passCtrl,
                  obscure: _obscure,
                  textInputAction: TextInputAction.next,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  validator: PasswordValidator.validate,
                ),
                const SizedBox(height: 16),
                UnderlineField(
                  label: 'Confirm Password',
                  controller: _confirmCtrl,
                  obscure: _obscure,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      PasswordValidator.validateConfirmation(v, _passCtrl.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.textMid, size: 15),
              const SizedBox(width: 6),
              Text(
                'Use at least ${PasswordValidator.minLength} characters.',
                style: const TextStyle(color: AppColors.textMid, fontSize: 12),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            _ErrorText(_error!),
            const SizedBox(height: 8),
            // Any server-side failure here (the client already validated the
            // password locally) means the link itself is the problem —
            // invalid, expired, or already used. Offer a fresh start.
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _requestNewLink,
                child: const Text('Request a new link'),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Center(
            child: GradientPillButton(
              label: 'RESET PASSWORD',
              loading: busy,
              onPressed: busy ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  4. Success
// ─────────────────────────────────────────────────────────────────────────────

class ResetSuccessScreen extends StatelessWidget {
  const ResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No back arrow, no way back into the (now consumed) reset flow.
    return PopScope(
      canPop: false,
      child: _AuthGradientScaffold(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.mint, size: 72),
              const SizedBox(height: 24),
              Text(
                'Password Reset Successfully',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Your password has been changed. You can now log in with your '
                'new password.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMid),
              ),
              const SizedBox(height: 32),
              GradientPillButton(
                label: 'BACK TO LOGIN',
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
