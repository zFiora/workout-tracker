import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

import 'package:workout_tracker/core/pb.dart'; // <-- our single PB instance
import 'package:workout_tracker/auth/authService.dart';
import 'package:workout_tracker/auth/authViewModel.dart';

import 'package:workout_tracker/home/account/accountReposirtry.dart'; // fix typo if needed
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
import 'package:workout_tracker/home/history/historyViewModel.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';
import 'package:workout_tracker/home/templates/templatesViewModel.dart';

import 'package:workout_tracker/common/splash/splashLoading.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ----- Hive -----
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

  // ----- PocketBase: restore token from secure storage -----
  await PB.I.bootstrapAuth(); // restores token & tries authRefresh()

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppManager()),
        // ----- Core singletons -----
        Provider<PocketBase>.value(value: PB.I.pb),

        // Auth (uses the same PB instance)
        ChangeNotifierProvider(
          create: (ctx) => AuthViewModel(AuthService(ctx.read<PocketBase>())),
        ),

        // Account repo + VM (fix file name: accountRepository.dart)
        Provider(create: (ctx) => AccountRepository(ctx.read<PocketBase>())),
        ChangeNotifierProvider(
          create: (ctx) => AccountViewModel(ctx.read<AccountRepository>()),
        ),

        // Friends
        ProxyProvider<PocketBase, FriendService>(
          update: (_, pb, __) => FriendService(pb),
        ),
        ChangeNotifierProvider(
          create: (ctx) => FriendsViewModel(ctx.read<FriendService>()),
        ),

        // ----- Streak sync wiring -----
        // Build StreakSyncService when we know the profileId from AccountViewModel
        ProxyProvider2<PocketBase, AccountViewModel, StreakSyncService?>(
          update: (_, pb, accountVM, __) {
            final profileId = accountVM.account?.id; // null until loaded
            if (profileId == null) return null;
            return StreakSyncService(pb: pb, profileId: profileId, userId: '');
          },
        ),

        // HistoryViewModel created once; keep its sync up-to-date
        ChangeNotifierProxyProvider<StreakSyncService?, HistoryViewModel>(
          create: (_) => HistoryViewModel(),
          update: (_, sync, vm) {
            vm ??= HistoryViewModel();
            vm.setSync(sync); // inject (or clear) when account changes
            return vm;
          },
        ),

        // Templates VM (independent)
        ChangeNotifierProvider(create: (_) => TemplatesViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

const brandStart = Color(0xFF0B4DD7);
const brandEnd = Color(0xFF0A2D73);
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
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          toolbarHeight: 56,
          elevation: 2,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashPage(), // decides where to go next
    );
  }
}
