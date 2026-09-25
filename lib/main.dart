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
import 'package:workout_tracker/common/models/sex.dart';
import 'package:workout_tracker/home/history/models/exNote.dart';
import 'package:workout_tracker/home/measure/models/macro_profile.dart';
import 'package:workout_tracker/home/measure/models/measurement_entry.dart';
import 'package:workout_tracker/home/measure/models/measure_profile.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/history/ViewModel/historyViewModel.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/viewmodels/templatesViewModel.dart';

import 'package:workout_tracker/home/session/active_session_manager.dart';
import 'package:workout_tracker/home/session/rest_timer_manager.dart';
import 'package:workout_tracker/home/session/rest_timer_notification_service.dart';
import 'package:workout_tracker/common/splash/splashLoading.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/core/services/deep_link_service.dart';
import 'package:workout_tracker/home/exercises/custom_exercises_repository.dart';
import 'package:workout_tracker/home/login/widgets/forgotPasswordPage.dart';
import 'package:workout_tracker/home/session/recap/workout_recap_store.dart';
import 'package:workout_tracker/home/support/services/device_context.dart';

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
    ..registerAdapter(SexAdapter())
    ..registerAdapter(ExerciseNoteAdapter());

  await Hive.openBox<ExerciseNote>('exerciseNotesBox');
  await Hive.openBox<WorkoutTemplateModel>('templatesBox');
  final historyBox = await Hive.openBox<WorkoutHistoryEntry>('historyBox');
  await Hive.openBox<MeasurementEntry>('measurementsBox');
  await Hive.openBox<MeasureProfile>('measureProfileBox');
  await Hive.openBox<MacroProfile>('macrosProfileBox');
  await Hive.openBox('prEventsBox');
  await Hive.openBox<bool>('syncedSessionsBox');
  await Hive.openBox<bool>('syncedMeasurementsBox');
  await Hive.openBox('activeSessionBox');
  await Hive.openBox<String>(CustomExercisesRepository.boxName);
  CustomExercisesRepository.I.load();
  await Hive.openBox<String>(WorkoutRecapStore.boxName);

  // Backfill a stable sync id onto any pre-sync history rows so they can be
  // pushed to the backend without duplicating.
  for (final key in historyBox.keys.toList()) {
    final entry = historyBox.get(key);
    if (entry != null && entry.id.isEmpty) {
      await historyBox.put(key, entry.copyWith(id: const Uuid().v4()));
    }
  }

  // Drop saved workout summaries (and their progress photos) whose workout was
  // deleted in an earlier run. Done here, not on delete, so History's Undo
  // keeps them. Best-effort: never blocks startup.
  try {
    await WorkoutRecapStore.I.pruneOrphans({
      for (final e in historyBox.values)
        if (e.id.isNotEmpty) e.id,
    });
  } catch (e) {
    debugPrint('[main] recap prune failed: $e');
  }

  await AuthToken.I.load();
  await DeviceContext.init();

  // If the app was cold-started from a password-reset deep link, grab the
  // token now (before the first frame) so we can route straight to the reset
  // screen with no flash of the normal startup flow.
  final deepLinks = DeepLinkService();
  final initialResetToken = await deepLinks.getInitialResetToken();

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
        ChangeNotifierProvider(
          create: (_) => RestTimerManager(RestTimerNotificationService()),
        ),
      ],
      child: MyApp(
        deepLinks: deepLinks,
        initialResetToken: initialResetToken,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.deepLinks, this.initialResetToken});

  /// Reused so we keep a single [DeepLinkService] across cold-start and
  /// warm-link handling. Optional so tests can build [MyApp] without the
  /// platform plugin.
  final DeepLinkService? deepLinks;

  /// Reset token the app was launched with, or null.
  final String? initialResetToken;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _resetRouteOpen = false;

  @override
  void initState() {
    super.initState();
    // Warm links: the app is already running when the reset link is tapped.
    widget.deepLinks?.listen(_openReset);
  }

  @override
  void dispose() {
    widget.deepLinks?.dispose();
    super.dispose();
  }

  void _openReset(String token) {
    final nav = _navigatorKey.currentState;
    if (nav == null || _resetRouteOpen) return; // guard against double links
    _resetRouteOpen = true;
    nav
        .push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(token: token),
          ),
        )
        .then((_) => _resetRouteOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<AppManager, ThemeMode>((m) => m.themeMode);
    final sex = context.select<AppManager, Sex>((m) => m.sex);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      title: 'ZLift',
      themeMode: themeMode,
      theme: buildLightTheme(sex: sex),
      darkTheme: buildDarkTheme(sex: sex),
      home: SplashPage(initialResetToken: widget.initialResetToken),
    );
  }
}
