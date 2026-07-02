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

  // ── Macro Profile ────────────────────────────────────────────────────────

  Future<MacroProfile> fetchMacroProfile() async {
    final result = await _client.get('/api/macro-profile');
    return switch (result) {
      ApiSuccess(:final data) => _macroFromJson(data as Map<String, dynamic>),
      ApiError(:final message) => throw Exception(message),
    };
  }

  Future<MacroProfile> putMacroProfile(MacroProfile profile) async {
    final result = await _client.put('/api/macro-profile', {
      'isMale': profile.isMale,
      'age': profile.age,
      'activityFactor': profile.activityFactor,
    });
    return switch (result) {
      ApiSuccess(:final data) => _macroFromJson(data),
      ApiError(:final message) => throw Exception(message),
    };
  }

  // ── Parsers ──────────────────────────────────────────────────────────────

  MeasurementEntry _entryFromJson(Map<String, dynamic> j) => MeasurementEntry(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String).toUtc(),
        weightKg: (j['weightKg'] as num).toDouble(),
      );

  MacroProfile _macroFromJson(Map<String, dynamic> j) => MacroProfile(
        isMale: j['isMale'] as bool,
        age: (j['age'] as num).toInt(),
        activityFactor: (j['activityFactor'] as num).toDouble(),
      );
}
