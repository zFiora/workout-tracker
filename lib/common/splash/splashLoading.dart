// lib/auth/splash_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/home/login/widgets/loginPage.dart';
import 'package:workout_tracker/home/login/widgets/registerPage.dart';

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

  @override
  void initState() {
    super.initState();
    // If already logged in, hop to home after a brief beat.
    Future<void>(() async {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      final isLoggedIn = context.read<AuthViewModel>().isLoggedIn;
      if (isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
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
            // tweak to your exact Figma hexes
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

                // Character image from your OLD splash path
                FadeTransition(
                  opacity: _heroOpacity,
                  child: SlideTransition(
                    position: _heroSlide,
                    child: Image.asset(
                      'assets/logo/splash_loading_logo.png',
                      fit: BoxFit.contain,
                      height: size.height * 0.42, // adjust to match Figma
                    ),
                  ),
                ),

                const Spacer(),

                // Buttons
                // Buttons
                FadeTransition(
                  opacity: _buttonsOpacity,
                  child: Builder(
                    builder: (context) {
                      // consistent sizing for both buttons
                      final double buttonWidth =
                          MediaQuery.of(context).size.width -
                          48; // 24px horizontal padding on both sides
                      const double buttonHeight = 56;
                      final BorderRadius pill = BorderRadius.circular(28);

                      return Column(
                        children: [
                          // SIGN IN — transparent bg, white border, white text
                          MyCustomButton(
                            label: 'SIGN IN',
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            ),
                            type: CustomButtonType
                                .elevated, // your widget renders white text for elevated
                            width: buttonWidth,
                            height: buttonHeight,
                            padding: EdgeInsets
                                .zero, // avoid double height from internal padding
                            style: ButtonStyle(
                              elevation: WidgetStateProperty.all(0),
                              backgroundColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              side: WidgetStateProperty.all(
                                const BorderSide(
                                  color: Colors.white,
                                  width: 1.6,
                                ),
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(borderRadius: pill),
                              ),
                              // If your button looks a bit tight, you can add minimumSize too:
                              fixedSize: WidgetStateProperty.all(
                                Size(buttonWidth, buttonHeight),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // SIGN UP — white bg, primary text
                          MyCustomButton(
                            label: 'SIGN UP',
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            ),
                            type: CustomButtonType
                                .outlined, // your widget uses primary text for outlined
                            width: buttonWidth,
                            height: buttonHeight,
                            padding: EdgeInsets.zero,
                            style: ButtonStyle(
                              elevation: WidgetStateProperty.all(0),
                              backgroundColor: WidgetStateProperty.all(
                                Colors.white,
                              ),
                              side: WidgetStateProperty.all(
                                const BorderSide(color: Colors.white, width: 0),
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(borderRadius: pill),
                              ),
                              fixedSize: WidgetStateProperty.all(
                                Size(buttonWidth, buttonHeight),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
