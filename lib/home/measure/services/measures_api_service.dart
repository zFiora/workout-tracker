import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/measure/models/macro_profile.dart';
import 'package:workout_tracker/home/measure/models/measurement_entry.dart';

class MeasuresApiService {
  final _client = ApiClient.instance;

  // ── Measurements ────────────────────────────────────────────────────────

  Future<List<MeasurementEntry>> fetchMeasurements() async {
    final result = await _client.get('/api/measurements');
    return switch (result) {
      ApiSuccess(:final data) => (data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_entryFromJson)
          .toList(),
      ApiError(:final message) => throw Exception(message),
    };
  }

  Future<MeasurementEntry> postMeasurement(MeasurementEntry entry) async {
    final result = await _client.post('/api/measurements', {
      'date': entry.date.toUtc().toIso8601String(),
      'weightKg': entry.weightKg,
    });
    return switch (result) {
      ApiSuccess(:final data) => _entryFromJson(data),
      ApiError(:final message) => throw Exception(message),
    };
  }

  Future<void> deleteMeasurement(String id) async {
    final result = await _client.delete('/api/measurements/$id');
    if (result is ApiError) throw Exception((result as ApiError).message);
  }

  // ── Macro Profile (also holds body height) ───────────────────────────────
  //
  // The backend keeps heightCm on the same macro-profile row as the BMR
  // inputs, so both travel together. GET returns 404 when no profile exists
  // yet; PUT is a full replace, so every write must include heightCm or it
  // would be nulled — callers pass the current value.

  /// [fallback] should be the current local profile — the backend doesn't
  /// store sex/DOB yet, so without a fallback a successful fetch would wipe
  /// out whatever the user already set locally.
  Future<({MacroProfile macro, double? heightCm})> fetchProfile({
    MacroProfile? fallback,
  }) async {
    final result = await _client.get('/api/macro-profile');
    return switch (result) {
      ApiSuccess(:final data) =>
        _profileFromJson(data as Map<String, dynamic>, fallback: fallback),
      ApiError(:final message) => throw Exception(message),
    };
  }

  Future<({MacroProfile macro, double? heightCm})> putProfile({
    required MacroProfile macro,
    required double? heightCm,
  }) async {
    final result = await _client.put('/api/macro-profile', {
      'isMale': macro.isMale,
      'age': macro.age,
      'activityFactor': macro.activityFactor,
      'heightCm': heightCm,
      // Not yet part of the backend contract — harmless to send ahead of
      // support (unknown JSON properties are ignored by the API today), and
      // picked up automatically once it is. See CLAUDE.md backend notes.
      if (macro.sex != Sex.unspecified) 'sex': macro.sex.name,
      if (macro.dateOfBirthUtc != null)
        'dateOfBirth':
            macro.dateOfBirthUtc!.toIso8601String().split('T').first,
    });
    return switch (result) {
      ApiSuccess(:final data) => _profileFromJson(data, fallback: macro),
      ApiError(:final message) => throw Exception(message),
    };
  }

  // ── Parsers ──────────────────────────────────────────────────────────────

  MeasurementEntry _entryFromJson(Map<String, dynamic> j) => MeasurementEntry(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String).toUtc(),
        weightKg: (j['weightKg'] as num).toDouble(),
      );

  /// [fallback] supplies sex/DOB when the server doesn't echo them back yet
  /// (it doesn't store them today) — a round-trip through the API must not
  /// silently drop locally-known profile fields the backend hasn't caught
  /// up on.
  ({MacroProfile macro, double? heightCm}) _profileFromJson(
    Map<String, dynamic> j, {
    MacroProfile? fallback,
  }) {
    final sexRaw = j['sex'] as String?;
    Sex? sex;
    for (final s in Sex.values) {
      if (s.name == sexRaw) {
        sex = s;
        break;
      }
    }
    sex ??= fallback?.sexValue;
    final dobRaw = j['dateOfBirth'] as String?;
    final dob = dobRaw != null ? DateTime.tryParse(dobRaw) : fallback?.dateOfBirthUtc;

    return (
      macro: MacroProfile(
        isMale: j['isMale'] as bool? ?? true,
        ageFallback: (j['age'] as num?)?.toInt() ?? 25,
        activityFactor: (j['activityFactor'] as num?)?.toDouble() ?? 1.375,
        sexValue: sex,
        dateOfBirthUtc: dob,
      ),
      heightCm: (j['heightCm'] as num?)?.toDouble(),
    );
  }
}
