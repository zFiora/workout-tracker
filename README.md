# Workout Tracker 🏋️

A structured, performance-focused mobile application built with Flutter to help users plan, track, and analyze their workouts with precision.

---

## 📱 Features

- **Custom Workout Templates** — Create and save personalized workout plans organized by muscle group
- **Session Logging** — Log exercises, sets, reps, and weights for every training session
- **Exercise History** — Browse past sessions and track performance over time
- **Progress Tracking** — Monitor personal records (PRs) and visualize weight progression
- **Exercise Database** — Access a built-in library of exercises with category filtering
- **Body Measurements** — Record and track body stats over time
- **Offline-First** — All data is stored locally using Hive, no internet connection required
- **Clean UI** — Intuitive and minimal interface optimized for use during workouts

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Local Storage | Hive |
| State Management | Flutter built-in |
| Platform | Android / iOS |

---

## 📂 Project Structure

```
lib/
├── models/          # Hive data models (Exercise, Session, Set, etc.)
├── screens/         # UI screens (Home, Workout, History, Progress)
├── widgets/         # Reusable UI components
├── services/        # Data access and business logic
└── main.dart
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK
- Android Studio or VS Code

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/workout-tracker.git

# Navigate to the project directory
cd workout-tracker

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.0.0
```

---

## 🔮 Planned Features

- [ ] Firebase sync for cloud backup
- [ ] Workout sharing between users
- [ ] REST API integration for exercise database
- [ ] Charts and analytics dashboard


