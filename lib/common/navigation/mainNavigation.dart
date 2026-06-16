// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/home/account/widgets/accountPage.dart';
import 'package:workout_tracker/home/exercises/widgets/exercisesPage.dart';
import 'package:workout_tracker/home/history/widgets/historyPage.dart';
import 'package:workout_tracker/home/measure/widgets/measuresPage.dart';
import 'package:workout_tracker/home/session/active_session_manager.dart';
import 'package:workout_tracker/home/session/pages/startSessionPage.dart';
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
    final sessionManager = context.watch<ActiveSessionManager>();

    final pages = <Widget>[
      const TemplatesPage(),
      const ExercisesPage(),
      const HistoryPage(),
      const MeasuresPage(),
      if (app.isOnline) const AccountPage(),
    ];

    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.fitness_center),
        label: 'Workout',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.list),
        label: 'Exercises',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'History',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.monitor_weight),
        label: 'Measures',
      ),
      if (app.isOnline)
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Account',
        ),
    ];

    return Scaffold(
      body: Column(
        children: [
          if (sessionManager.hasActiveSession)
            _SessionBanner(manager: sessionManager),
          Expanded(child: pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: items,
      ),
    );
  }
}

class _SessionBanner extends StatelessWidget {
  const _SessionBanner({required this.manager});
  final ActiveSessionManager manager;

  @override
  Widget build(BuildContext context) {
    final elapsed = manager.session?.elapsedText ?? '00:00:00';
    final name = manager.templateName ?? 'Active Session';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StartSessionPage()),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D3B7A), Color(0xFF3B82F6)],
          ),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 12,
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 8,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Tap to return · $elapsed',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
