import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home/templates/models/workoutTemplateModel.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/splash/splashLoading.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/templates/templatesViewModel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(WorkoutTemplateModelAdapter());

  
  await Hive.openBox<WorkoutTemplateModel>('templatesBox');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExercisesViewModel()),
        ChangeNotifierProvider(create: (_) => TemplatesViewModel()),
      ],
      child: const MyApp(),
    ),
  );
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
        primarySwatch: Colors.teal,
        textTheme: Theme.of(context).textTheme.copyWith(
          bodyLarge: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.grey[700]),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ), // main color palette
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
