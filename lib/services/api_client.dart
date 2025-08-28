// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:escort/config/api_config.dart';
import 'package:escort/services/user_session.dart';
import 'package:escort/services/token_storage.dart';

class ApiClient {
  // Core request handler with optional auth and auto-refresh on 401
  static Future<http.Response> _request(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    bool auth = true,
  }) async {
    // Merge headers and attach token if requested
    final mergedHeaders = <String, String>{'Content-Type': 'application/json'};
    if (headers != null) mergedHeaders.addAll(headers);

    String? token;
    if (auth) {
      token = await UserSession.getAccessToken();
      token ??= await TokenStorage.getAccessToken();
      if (token != null) mergedHeaders['Authorization'] = 'Bearer $token';
    }

    Future<http.Response> send() {
      switch (method) {
        case 'GET':
          return http.get(uri, headers: mergedHeaders);
        case 'POST':
          return http.post(uri, headers: mergedHeaders, body: body);
        case 'PUT':
          return http.put(uri, headers: mergedHeaders, body: body);
        case 'DELETE':
          return http.delete(uri, headers: mergedHeaders, body: body);
        default:
          throw UnsupportedError('Unsupported method $method');
      }
    }

    var res = await send();

    // If unauthorized and we used auth, try to refresh token once
    if (auth && res.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Update header with the new token
        final newToken = await UserSession.getAccessToken() ?? await TokenStorage.getAccessToken();
        if (newToken != null) mergedHeaders['Authorization'] = 'Bearer $newToken';
        res = await send();
      }
    }

    return res;
  }

  static Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      final rt2 = await UserSession.getAccessToken(); // not refresh, but keep logic simple
      final token = refreshToken ?? rt2; // prefer TokenStorage refresh
      if (token == null) return false;

      final url = Uri.parse('${ApiConfig.auth}/refresh');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': token}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final newAccess = data['access_token'] as String?;
        final expiresAt = data['expires_at'] as String?;
        if (newAccess != null) {
          // Update both storages if available
          final currentUserType = await UserSession.getUserType() ?? await TokenStorage.getUserType();
          final currentUserId = await TokenStorage.getUserId();
          if (expiresAt != null && currentUserId != null && currentUserType != null) {
            await TokenStorage.storeTokens(
              accessToken: newAccess,
              refreshToken: await TokenStorage.getRefreshToken() ?? '',
              userId: currentUserId,
              userType: currentUserType,
              expiresAt: expiresAt,
            );
          }

          // Also update UserSession minimal state
          final existing = await UserSession.getCurrentUserData() ?? {};
          await UserSession.saveUserSession(
            userData: existing,
            accessToken: newAccess,
            refreshToken: await TokenStorage.getRefreshToken(),
            userType: currentUserType ?? 'user',
          );
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Public helpers
  static Future<Map<String, dynamic>> getJson(String url, {bool auth = true}) async {
    final res = await _request('GET', Uri.parse(url), auth: auth);
    return _decode(res);
  }

  static Future<Map<String, dynamic>> postJson(String url, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await _request('POST', Uri.parse(url), body: json.encode(body), auth: auth);
    return _decode(res);
  }

  static Future<Map<String, dynamic>> putJson(String url, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await _request('PUT', Uri.parse(url), body: json.encode(body), auth: auth);
    return _decode(res);
  }

  static Future<Map<String, dynamic>> deleteJson(String url, {Map<String, dynamic>? body, bool auth = true}) async {
    final res = await _request('DELETE', Uri.parse(url), body: body == null ? null : json.encode(body), auth: auth);
    return _decode(res);
  }

  static Map<String, dynamic> _decode(http.Response res) {
    final status = res.statusCode;
    Map<String, dynamic> data;
    try {
      final decoded = json.decode(res.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else {
        data = {'data': decoded};
      }
    } catch (_) {
      data = {'data': res.body};
    }
    data['statusCode'] = status;
    return data;
  }
}

