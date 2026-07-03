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

  Future<({MacroProfile macro, double? heightCm})> fetchProfile() async {
    final result = await _client.get('/api/macro-profile');
    return switch (result) {
      ApiSuccess(:final data) => _profileFromJson(data as Map<String, dynamic>),
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
    });
    return switch (result) {
      ApiSuccess(:final data) => _profileFromJson(data),
      ApiError(:final message) => throw Exception(message),
    };
  }

  // ── Parsers ──────────────────────────────────────────────────────────────

  MeasurementEntry _entryFromJson(Map<String, dynamic> j) => MeasurementEntry(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String).toUtc(),
        weightKg: (j['weightKg'] as num).toDouble(),
      );

  ({MacroProfile macro, double? heightCm}) _profileFromJson(
    Map<String, dynamic> j,
  ) =>
      (
        macro: MacroProfile(
          isMale: j['isMale'] as bool? ?? true,
          age: (j['age'] as num?)?.toInt() ?? 25,
          activityFactor: (j['activityFactor'] as num?)?.toDouble() ?? 1.375,
        ),
        heightCm: (j['heightCm'] as num?)?.toDouble(),
      );
}
