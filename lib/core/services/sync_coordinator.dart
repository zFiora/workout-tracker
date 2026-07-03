import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/core/auth_token.dart';

/// Best-effort backend calls that don't belong to a feature view-model.
class SyncCoordinator {
  final _client = ApiClient.instance;

  /// Publishes a template publicly (POST /api/templates with isPublic).
  Future<bool> shareTemplate(Map<String, dynamic> templateJson) async {
    if (!AuthToken.I.isValid) return false;
    final result = await _client.post(
      '/api/templates',
      {...templateJson, 'isPublic': true},
    );
    return result.isSuccess;
  }
}
