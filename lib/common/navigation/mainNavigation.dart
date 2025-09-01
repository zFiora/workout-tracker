// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:workout_tracker/home/account/widgets/accountPage.dart';
import 'package:workout_tracker/home/exercises/widgets/exercisesPage.dart';
import 'package:workout_tracker/home/history/widgets/historyPage.dart';
import 'package:workout_tracker/home/measure/widgets/measuresPage.dart';
import 'package:workout_tracker/home/templates/widgets/templatesPage.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TemplatesPage(),
    ExercisesPage(),
    AccountPage(),
    HistoryPage(),
    MeasuresPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // <- each page has its own Scaffold
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: "Workout",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Exercises"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight),
            label: "Measures",
          ),
        ],
      ),
    );
  }
}
