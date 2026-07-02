import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';

class PrEventsApiService {
  final _client = ApiClient.instance;

  Future<void> pushEvent(Map<String, dynamic> prEvent) async {
    final result = await _client.post('/api/pr-events', prEvent);
    if (result is ApiError) throw Exception((result as ApiError).message);
  }

  Future<void> pushEvents(List<Map<String, dynamic>> prEvents) async {
    for (final event in prEvents) {
      await pushEvent(event);
    }
  }
}
