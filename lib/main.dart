import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workout_tracker/auth/authService.dart';
import 'package:workout_tracker/auth/authViewModel.dart';
import 'package:workout_tracker/home/history_page/historyViewModel.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/splash/splashLoading.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';
import 'package:workout_tracker/home/templates/templatesViewModel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive
    ..registerAdapter(DurationAdapter())
    ..registerAdapter(SetTypeAdapter())
    ..registerAdapter(PerformedSetAdapter())
    ..registerAdapter(ExerciseLogAdapter())
    ..registerAdapter(WorkoutHistoryEntryAdapter())
    ..registerAdapter(WorkoutTemplateModelAdapter());
  await Hive.openBox<WorkoutTemplateModel>('templatesBox');
  await Hive.openBox<WorkoutHistoryEntry>('historyBox');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HistoryViewModel()),
        ChangeNotifierProvider(create: (_) => TemplatesViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel(AuthService())),
      ],
      child: const MyApp(),
    ),
  );
}

const brandStart = Color(0xFF0B4DD7);
const brandEnd = Color(0xFF0A2D73);

// pick something between them: 0.0 = start, 1.0 = end
final seed = Color.lerp(brandStart, brandEnd, 0.5)!;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Workout Tracker',
      theme: ThemeData(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),

        textTheme: Theme.of(context).textTheme.copyWith(
          bodyLarge: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(color: Colors.grey[700]),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ), // main color palette
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white, // text/icon color
          toolbarHeight: 56,
          elevation: 2,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashPage(),
    );
  }
}
