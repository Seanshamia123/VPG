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

  static Future<Map<String, dynamic>> updateProfile(
    int userId, {
    String? name,
    String? phoneNumber,
    String? location,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (location != null) 'location': location,
    };
    return ApiClient.putJson(
      '${ApiConfig.api}/users/$userId',
      body,
      auth: true,
    );
  }

  static Future<Map<String, dynamic>> getBlockedUsers() async {
    return ApiClient.getJson(
      '${ApiConfig.api}/users/blocked',
      auth: true,
    );
  }

  static Future<Map<String, dynamic>> blockUser(int blockedId) async {
    return ApiClient.postJson(
      '${ApiConfig.api}/users/block',
      {'blocked_id': blockedId},
      auth: true,
    );
  }

  static Future<Map<String, dynamic>> unblockUser(int blockedId) async {
    return ApiClient.deleteJson(
      '${ApiConfig.api}/users/unblock/$blockedId',
      auth: true,
    );
  }
}
