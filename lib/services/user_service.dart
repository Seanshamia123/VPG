// lib/services/user_service.dart
// import 'dart:convert';
import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';

class UserService {
  static Future<Map<String, dynamic>?> getProfile(int userId) async {
    final data = await ApiClient.getJson(
      '${ApiConfig.api}/users/$userId',
      auth: true,
    );
    if (data['statusCode'] != null && data['statusCode'] >= 400) return null;
    return data;
  }

  static Future<Map<String, dynamic>> uploadAvatar(
    int userId,
    String base64Image,
  ) async {
    final body = {'image': base64Image};
    return ApiClient.postJson(
      '${ApiConfig.api}/users/$userId/avatar',
      body,
      auth: true,
    );
  }
}
