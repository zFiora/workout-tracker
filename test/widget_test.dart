// Smoke test: the app must be able to open and be navigated even when the
// backend is completely unreachable (this test never touches the network at
// all — it exercises exactly the "server down" cold-start path).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/common/models/sex.dart';
import 'package:workout_tracker/common/splash/splashLoading.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/home/measure/models/macro_profile.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('workout_tracker_test');
    Hive.init(tempDir.path);
    Hive
      ..registerAdapter(MacroProfileAdapter())
      ..registerAdapter(SexAdapter());
    await Hive.openBox<MacroProfile>('macrosProfileBox');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('splash screen opens with no backend/network available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppManager())],
        child: MaterialApp(
          theme: buildDarkTheme(),
          home: const SplashPage(),
        ),
      ),
    );

    // Before the (purely local, no-network) auth check resolves.
    await tester.pump();
    expect(find.text('ZLift'), findsOneWidget);

    // Let the splash's local auth check + entry animation finish.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 1000));

    // No token was ever saved, so splash lands on the signed-out state —
    // reachable regardless of whether a server exists to talk to.
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Continue without account →'), findsOneWidget);
  });
}
