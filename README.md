# workout_tracker

A new Flutter project.

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.8.1 — verify with `flutter --version`
- A running [PocketBase](https://pocketbase.io) instance (local or hosted)

### Clone & install

```bash
git clone <repo-url>
cd workout_tracker
flutter pub get
```

### Configure the backend URL

The default URL targets the Android emulator's localhost. Change it without touching source code using `--dart-define`:

```bash
# Real Android device on your LAN
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8090

# Production build
flutter build apk --release --dart-define=API_BASE_URL=https://api.yourapp.com
```

The constant is in [lib/core/api/api_config.dart](lib/core/api/api_config.dart):

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8090',
);
```

### Run

```bash
flutter run           # debug (hot-reload enabled)
flutter run --release # release mode
```

---

## Common Commands

```bash
# Install / update dependencies
flutter pub get

# Regenerate Hive adapters after editing any @HiveType model
flutter pub run build_runner build --delete-conflicting-outputs

# Static analysis (should report 0 errors, 0 warnings)
flutter analyze

# All tests
flutter test

# Single test file
flutter test test/path/to/test.dart

# Release APK
flutter build apk --release

# iOS release (requires macOS + Xcode)
flutter build ios --release
```

---

## Hive Type ID Registry

Never reuse a `typeId` — Hive stores the integer in binary and will silently corrupt data if IDs collide.

| typeId | Class |
|--------|-------|
| 1 | `SetType` (enum) |
| 2 | `PerformedSet` |
| 3 | `ExerciseLog` |
| 4 | `WorkoutHistoryEntry` |
| 5 | `PlannedSet` |
| 50 | `DurationAdapter` (manual) |
| 101 | `WorkoutTemplateModel` |
| 110–112 | `MeasurementEntry`, `MeasureProfile`, `MacroProfile` |
| 120 | `ExerciseNote` |

### Adding a new Hive model

1. Annotate the class with `@HiveType(typeId: N)` using a fresh ID.
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`.
3. Register the adapter in `main()`: `Hive.registerAdapter(YourModelAdapter())`.
4. Open the box: `await Hive.openBox<YourModel>('yourBoxName')`.
5. Add the new ID + class to the table above.

---

## PocketBase Schema

### `users` (built-in auth collection)

| Field | Type | Purpose |
|---|---|---|
| `displayName` | text | shown in UI and leaderboard |
| `avatar` | file | profile photo |
| `currentStreak` | number | days in current unbroken streak |
| `bestStreak` | number | all-time highest streak |
| `lastWorkoutDate` | date | ISO date used for streak gap calculation |
| `streakRunStartedOn` | date | start of the current streak run |

### `friendships`

| Field | Type | Notes |
|---|---|---|
| `user` | relation → users | requester |
| `friend` | relation → users | recipient |
| `status` | text | `pending` / `accepted` / `blocked` |

### `workouts` *(future — session sync)*

| Field | Type |
|---|---|
| `user` | relation → users |
| `templateId` | text |
| `templateName` | text |
| `startedAt` | date |
| `endedAt` | date |
| `durationMs` | number |
| `logs` | json (array of `ExerciseLog.toJson()`) |

### `pr_events` *(future — PR sync)*

| Field | Type |
|---|---|
| `user` | relation → users |
| `exerciseId` | number |
| `weight` | number |
| `reps` | number |
| `created` | date (auto) |

### `templates` *(future — share)*

| Field | Type |
|---|---|
| `user` | relation → users |
| `name` | text |
| `iconPath` | text |
| `exerciseIds` | json |
| `isPublic` | bool |

---

## Architecture Decisions

### Offline-first, network as enhancement

All writes go to Hive first. Every feature section has an abstract repository interface (`TemplatesRepository`, `HistoryRepository`, …) with a `Hive*` concrete implementation. To go cloud, write an `Api*` implementation and swap the binding in `main.dart`'s provider tree — the UI doesn't change.

### `ApiResult<T>` instead of exceptions

`lib/core/api/api_result.dart` defines a sealed type:

```dart
sealed class ApiResult<T> {}
final class ApiSuccess<T> extends ApiResult<T> { final T data; }
final class ApiError<T>   extends ApiResult<T> { final String message; }
```

Every network call returns this; nothing throws across async widget boundaries. UI code pattern-matches:

```dart
switch (result) {
  case ApiSuccess(:final data): renderList(data);
  case ApiError(:final message): showError(message);
}
```

### PR detection is fully local

`WorkoutSessionPrService` compares the current set against the local Hive history. No network needed. `SyncCoordinator.pushPrEvents()` can relay the events to PocketBase afterwards.

### Streak is a pure computation

`StreakCalculator.compute(Iterable<DateTime> workoutDates)` is stateless — no database reads, no network. It runs synchronously every time a Hive change fires in `HistoryViewModel`. The PocketBase `currentStreak` field is the authoritative server copy; `StreakSyncService.bumpIfFirstWorkoutToday()` keeps them in sync.

### Theme persists across restarts

`AppManager` (a `ChangeNotifier` at the root) holds `ThemeMode`. On construction it reads from `SharedPreferences`. `MaterialApp` binds `themeMode` directly to `AppManager.themeMode` via `context.select`.

---

## Connecting a Real Backend — Step by Step

All the wiring points are already in place:

| Feature | What to do |
|---|---|
| **Session sync** | In `HistoryViewModel.save()`, call `SyncCoordinator.pushWorkoutEntry(entry)` when `AppManager.isOnline` |
| **PR sync** | In `HistoryViewModel.saveWithPrEvents()`, call `SyncCoordinator.pushPrEvents(events)` |
| **Streak sync** | Uncomment `unawaited(s.sync(_streak))` in `HistoryViewModel._maybeSync()` |
| **Leaderboard** | Already live — `LeaderboardService.fetchStreakLeaderboard()` queries `users` sorted by `currentStreak` |
| **Share template** | Already live — "Share with friends" menu calls `SyncCoordinator.shareTemplate()` |
| **Friends** | `FriendService` + `FriendsViewModel` are implemented; wire to `friendships` collection |

---

## Roadmap

- [ ] Offline → online sync queue (persist unsent events while offline, flush on reconnect)
- [ ] Clone a shared template from a friend's profile
- [ ] Per-exercise PR comparison chart against friends
- [ ] Push notifications — friend workout alerts, streak reminders
- [ ] Rest timer with haptic feedback
- [ ] Custom exercise creation (user-defined exercises stored in Hive)
- [ ] Weight units toggle (kg ↔ lbs)
- [ ] Apple Health / Google Fit export
- [ ] Data export (CSV / JSON)
- [ ] Multiple body measurement types (body fat %, chest, waist, arms…)

---

## Contributing

1. Branch from `main`
2. Run `flutter analyze` before opening a PR — 0 errors, 0 warnings expected
3. Re-run `build_runner` if you touched any `@HiveType` model
4. Keep the Hive type ID table in both `README.md` and `CLAUDE.md` in sync
