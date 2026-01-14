import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/navigation/mainNavigation.dart';
import 'package:workout_tracker/core/pb.dart';
import 'package:workout_tracker/home/login/widgets/gradiantPillButton.dart';
import 'package:workout_tracker/home/login/widgets/loginPage.dart';
import 'package:workout_tracker/home/login/widgets/registerPage.dart';
import 'package:workout_tracker/main.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final Animation<double> _heroOpacity = CurvedAnimation(
    parent: _ac,
    curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
  );

  late final Animation<Offset> _heroSlide =
      Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _ac,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
        ),
      );

  late final Animation<double> _buttonsOpacity = CurvedAnimation(
    parent: _ac,
    curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
  );

  bool _checking = true;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Future<void> _goMain() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  Future<void> _decide() async {
    if (_navigated) return;

    final pb = PB.I.pb;

    // Try refresh once if token exists but not valid
    if (!pb.authStore.isValid && pb.authStore.token.isNotEmpty) {
      try {
        await pb.collection('users').authRefresh();
      } catch (_) {}
    }

    final authed = pb.authStore.isValid && pb.authStore.record != null;

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    if (authed) {
      // Online session
      context.read<AppManager>().setOnline();
      await _goMain();
    } else {
      // Show buttons every time (Option B)
      setState(() => _checking = false);
    }
  }

  Future<void> _continueOffline() async {
    // In-memory only (Option B)
    context.read<AppManager>().setOffline();

    // Optional: clear PB state to avoid confusion
    try {
      PB.I.pb.authStore.clear();
    } catch (_) {}

    if (!mounted) return;
    await _goMain();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D2B66), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'Gym Tracker',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                ),
                const Spacer(),
                FadeTransition(
                  opacity: _heroOpacity,
                  child: SlideTransition(
                    position: _heroSlide,
                    child: Image.asset(
                      'assets/logo/splash_loading_logo.png',
                      fit: BoxFit.contain,
                      height: size.height * 0.42,
                    ),
                  ),
                ),
                const Spacer(),
                FadeTransition(
                  opacity: _buttonsOpacity,
                  child: _checking
                      ? const Padding(
                          padding: EdgeInsets.only(bottom: 28),
                          child: CircularProgressIndicator(color: Colors.blue),
                        )
                      : Column(
                          children: [
                            GradientPillButton(
                              whiteColor: true,
                              labelColor: brandEnd,
                              label: 'SIGN IN',
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GradientPillButton(
                              label: 'SIGN UP',
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: _continueOffline,
                              child: const Text(
                                'CONTINUE OFFLINE',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
