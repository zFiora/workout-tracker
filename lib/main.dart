import 'package:flutter/material.dart';
import 'package:workout_tracker/common/splash/splashLoading.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Workout Tracker',
      theme: ThemeData(
        useMaterial3: false, // keep Material 2 look (smaller appBar etc.)
        primarySwatch: Colors.teal, // main color palette
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white, // text/icon color
          toolbarHeight: 56,
          elevation: 2,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}
