// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/home/account/widgets/accountPage.dart';
import 'package:workout_tracker/home/exercises/widgets/exercisesPage.dart';
import 'package:workout_tracker/home/history/widgets/historyPage.dart';
import 'package:workout_tracker/home/measure/widgets/measuresPage.dart';
import 'package:workout_tracker/home/templates/pages/templatesPage.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppManager>();

    // Pages must match the order of BottomNavigationBar items.
    final pages = <Widget>[
      const TemplatesPage(),
      const ExercisesPage(),
      const HistoryPage(),
      const MeasuresPage(),
      if (app.isOnline) const AccountPage(),
    ];

    // If the tab count changes (e.g., logout hides Account), avoid out-of-range.
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.fitness_center),
        label: "Workout",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.list),
        label: "Exercises",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: "History",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.monitor_weight),
        label: "Measures",
      ),
      if (app.isOnline)
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Account",
        ),
    ];

    return Scaffold(
      body: pages[_currentIndex], // each page can have its own Scaffold
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: items,
      ),
    );
  }
}
