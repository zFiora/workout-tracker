import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:workout_tracker/core/auth_token.dart';
import 'package:workout_tracker/auth/authService.dart';
import 'package:workout_tracker/auth/authViewModel.dart';

import 'package:workout_tracker/home/account/accountReposirtry.dart';
import 'package:workout_tracker/home/account/accountViewModel.dart';
import 'package:workout_tracker/home/account/model/streakSyncService.dart';
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
  await Hive.openBox<WorkoutHistoryEntry>('historyBox');
  await Hive.openBox<MeasurementEntry>('measurementsBox');
  await Hive.openBox<MeasureProfile>('measureProfileBox');
  await Hive.openBox<MacroProfile>('macrosProfileBox');
  await Hive.openBox('prEventsBox');

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

        ProxyProvider<AccountViewModel, StreakSyncService?>(
          update: (_, accountVM, prev) {
            final userId = AuthToken.I.userId;
            if (userId == null) return null;
            return StreakSyncService(userId: userId);
          },
        ),

        ChangeNotifierProxyProvider<StreakSyncService?, HistoryViewModel>(
          create: (_) => HistoryViewModel(),
          update: (_, sync, vm) {
            vm ??= HistoryViewModel();
            vm.setSync(sync);
            return vm;
          },
        ),

        ChangeNotifierProvider(create: (_) => TemplatesViewModel()),
        ChangeNotifierProvider(create: (_) => ActiveSessionManager()),
      ],
      child: const MyApp(),
    ),
  );
}

// Brand palette
const kPrimaryBlue = Color(0xFF3B82F6);
const kDarkBg = Color(0xFF0D1117);
const kDarkSurface = Color(0xFF161B22);
const kDarkCard = Color(0xFF21262D);

ThemeData _buildDarkTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF3B82F6),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF1D3B7A),
    onPrimaryContainer: Color(0xFFBFD9FF),
    secondary: Color(0xFF10B981),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF064E3B),
    onSecondaryContainer: Color(0xFF6EE7B7),
    tertiary: Color(0xFFF59E0B),
    onTertiary: Colors.black,
    tertiaryContainer: Color(0xFF78350F),
    onTertiaryContainer: Color(0xFFFDE68A),
    error: Color(0xFFFF6B6B),
    onError: Colors.white,
    errorContainer: Color(0xFF5C1A1A),
    onErrorContainer: Color(0xFFFFB4AB),
    surface: kDarkBg,
    onSurface: Color(0xFFE6EDF3),
    surfaceContainerHighest: kDarkCard,
    onSurfaceVariant: Color(0xFF8B949E),
    outline: Color(0xFF30363D),
    outlineVariant: Color(0xFF21262D),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE6EDF3),
    onInverseSurface: kDarkBg,
    inversePrimary: Color(0xFF1D3B7A),
    surfaceTint: Color(0xFF3B82F6),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kDarkBg,
    cardColor: kDarkCard,
    cardTheme: CardThemeData(
      color: kDarkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF30363D), width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kDarkBg,
      foregroundColor: Color(0xFFE6EDF3),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kDarkSurface,
      selectedItemColor: Color(0xFF3B82F6),
      unselectedItemColor: Color(0xFF8B949E),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF30363D),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kDarkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: kDarkCard,
      side: BorderSide(color: Color(0xFF30363D)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kDarkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kDarkCard,
      contentTextStyle: TextStyle(color: Color(0xFFE6EDF3)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Color(0xFFE6EDF3)),
      displayMedium: TextStyle(color: Color(0xFFE6EDF3)),
      displaySmall: TextStyle(color: Color(0xFFE6EDF3)),
      headlineLarge: TextStyle(color: Color(0xFFE6EDF3), fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(color: Color(0xFFE6EDF3), fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(color: Color(0xFFE6EDF3), fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: Color(0xFFE6EDF3), fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: Color(0xFFE6EDF3), fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: Color(0xFFE6EDF3)),
      bodyLarge: TextStyle(color: Color(0xFFE6EDF3)),
      bodyMedium: TextStyle(color: Color(0xFFCDD4DC)),
      bodySmall: TextStyle(color: Color(0xFF8B949E)),
      labelLarge: TextStyle(color: Color(0xFFE6EDF3), fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: Color(0xFFCDD4DC)),
      labelSmall: TextStyle(color: Color(0xFF8B949E)),
    ),
  );
}

ThemeData _buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2563EB),
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF6F8FA),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
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
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const SplashPage(),
    );
  }
}
