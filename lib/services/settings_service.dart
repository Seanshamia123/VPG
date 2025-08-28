// lib/services/settings_service.dart
import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';

class SettingsService {
  static Future<Map<String, dynamic>?> getByUserId(int userId) async {
    final data = await ApiClient.getJson('${ApiConfig.api}/user-settings/user/$userId', auth: true);
    if (data['statusCode'] != null && data['statusCode'] >= 400) return null;
    return data;
  }

  static Future<Map<String, dynamic>> createOrUpdate(int userId, Map<String, dynamic> payload) async {
    return ApiClient.postJson('${ApiConfig.api}/user-settings/user/$userId/create-or-update', payload, auth: true);
  }
}

