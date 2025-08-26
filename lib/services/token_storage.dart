// services/token_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  // Keys for storing data
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userTypeKey = 'user_type';
  static const String _expiresAtKey = 'expires_at';

  // Store authentication data
  static Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String userType,
    required String expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userTypeKey, userType);
    await prefs.setString(_expiresAtKey, expiresAt);
  }

  // Get stored data
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  static Future<String?> getExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_expiresAtKey);
  }

  // Check if user is logged in with valid token
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    final expiresAt = await getExpiresAt();
    
    if (accessToken == null || expiresAt == null) {
      return false;
    }

    // Check if token is expired
    final expiryDate = DateTime.parse(expiresAt);
    final now = DateTime.now();
    
    return now.isBefore(expiryDate);
  }

  // Clear all stored data (for logout)
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_expiresAtKey);
  }

  // Get authorization headers for API calls
  static Future<Map<String, String>?> getAuthHeaders() async {
    final accessToken = await getAccessToken();
    
    if (accessToken == null) {
      return null;
    }

    return {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }
}