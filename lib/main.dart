import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:workout_tracker/core/auth_token.dart';
import 'package:workout_tracker/auth/authService.dart';
import 'package:workout_tracker/auth/authViewModel.dart';

import 'package:workout_tracker/home/account/accountReposirtry.dart';
import 'package:workout_tracker/home/account/accountViewModel.dart';
import 'package:workout_tracker/home/friends/friendsService.dart';
import 'package:workout_tracker/home/friends/friendsViewModel.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/home/history/models/exNote.dart';
import 'package:workout_tracker/home/measure/models/macro_profile.dart';
import 'package:workout_tracker/home/measure/models/measurement_entry.dart';
import 'package:workout_tracker/home/measure/models/measure_profile.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/history/ViewModel/historyViewModel.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';

import 'package:workout_tracker/home/session/active_session_manager.dart';
import 'package:workout_tracker/common/splash/splashLoading.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive
    ..registerAdapter(DurationAdapter())
    ..registerAdapter(SetTypeAdapter())
    ..registerAdapter(PerformedSetAdapter())
    ..registerAdapter(ExerciseLogAdapter())
    ..registerAdapter(WorkoutHistoryEntryAdapter())
    ..registerAdapter(WorkoutTemplateModelAdapter())
    ..registerAdapter(MeasurementEntryAdapter())
    ..registerAdapter(MeasureProfileAdapter())
    ..registerAdapter(MacroProfileAdapter())
    ..registerAdapter(ExerciseNoteAdapter());

  await Hive.openBox<ExerciseNote>('exerciseNotesBox');
  await Hive.openBox<WorkoutTemplateModel>('templatesBox');
  final historyBox = await Hive.openBox<WorkoutHistoryEntry>('historyBox');
  await Hive.openBox<MeasurementEntry>('measurementsBox');
  await Hive.openBox<MeasureProfile>('measureProfileBox');
  await Hive.openBox<MacroProfile>('macrosProfileBox');
  await Hive.openBox('prEventsBox');
  await Hive.openBox<bool>('syncedSessionsBox');

  // Backfill a stable sync id onto any pre-sync history rows so they can be
  // pushed to the backend without duplicating.
  for (final key in historyBox.keys.toList()) {
    final entry = historyBox.get(key);
    if (entry != null && entry.id.isEmpty) {
      await historyBox.put(key, entry.copyWith(id: const Uuid().v4()));
    }
  }

  await AuthToken.I.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppManager()),

        ChangeNotifierProvider(
          create: (_) => AuthViewModel(AuthService()),
        ),

        Provider(create: (_) => AccountRepository()),
        ChangeNotifierProvider(
          create: (ctx) => AccountViewModel(ctx.read<AccountRepository>()),
        ),

        Provider(create: (_) => FriendService()),
        ChangeNotifierProvider(
          create: (ctx) => FriendsViewModel(ctx.read<FriendService>()),
        ),

        // Streak is server-owned; the client reads it from AccountViewModel
        // (backed by /api/users/me) rather than computing it locally.
        ChangeNotifierProvider(create: (_) => HistoryViewModel()),

        ChangeNotifierProvider(create: (_) => TemplatesViewModel()),
        ChangeNotifierProvider(create: (_) => ActiveSessionManager()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<AppManager, ThemeMode>((m) => m.themeMode);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Tracker',
      themeMode: themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: const SplashPage(),
    );
  }
}
