import 'package:poketto/core/helpers/json_helpers.dart';
import 'package:poketto/core/network/api_client.dart';

class UserSettingsService {
  final ApiClient _apiClient;

  const UserSettingsService(this._apiClient);

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _apiClient.get('/user-settings');
    return readMapPayload(response, const ['user_settings', 'settings']);
  }

  Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.put('/user-settings', body: payload);
    return readMapPayload(response, const ['user_settings', 'settings']);
  }
}
