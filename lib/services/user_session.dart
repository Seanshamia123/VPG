// services/user_session.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserSession {
  static const String _userDataKey = 'user_data';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userTypeKey = 'user_type';
  static const String _isLoggedInKey = 'is_logged_in';

  // Current user data (in-memory cache)
  static Map<String, dynamic>? _currentUserData;
  static String? _currentAccessToken;
  static String? _currentUserType;

  // Save user session after login
  static Future<void> saveUserSession({
    required Map<String, dynamic> userData,
    required String accessToken,
    String? refreshToken,
    required String userType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Store in SharedPreferences
    await prefs.setString(_userDataKey, json.encode(userData));
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_userTypeKey, userType);
    await prefs.setBool(_isLoggedInKey, true);
    
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    
    // Update in-memory cache
    _currentUserData = userData;
    _currentAccessToken = accessToken;
    _currentUserType = userType;
    
    print('=== USER SESSION SAVED ===');
    print('User Data: $userData');
    print('User Type: $userType');
    print('=========================');
  }

  // Get current user data
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (_currentUserData != null) {
      return _currentUserData;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    
    if (userDataString != null) {
      try {
        _currentUserData = json.decode(userDataString);
        return _currentUserData;
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    
    return null;
  }

  // Get current access token
  static Future<String?> getAccessToken() async {
    if (_currentAccessToken != null) {
      return _currentAccessToken;
    }
    
    final prefs = await SharedPreferences.getInstance();
    _currentAccessToken = prefs.getString(_accessTokenKey);
    return _currentAccessToken;
  }

  // Get current user type
  static Future<String?> getUserType() async {
    if (_currentUserType != null) {
      return _currentUserType;
    }
    
    final prefs = await SharedPreferences.getInstance();
    _currentUserType = prefs.getString(_userTypeKey);
    return _currentUserType;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear user session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_userDataKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userTypeKey);
    await prefs.setBool(_isLoggedInKey, false);
    
    // Clear in-memory cache
    _currentUserData = null;
    _currentAccessToken = null;
    _currentUserType = null;
    
    print('=== USER SESSION CLEARED ===');
  }

  // Get user's name
  static Future<String?> getUserName() async {
    final userData = await getCurrentUserData();
    return userData?['name'] ?? userData?['username'];
  }

  // Get user's email
  static Future<String?> getUserEmail() async {
    final userData = await getCurrentUserData();
    return userData?['email'];
  }

  // Get user's ID
  static Future<dynamic> getUserId() async {
    final userData = await getCurrentUserData();
    return userData?['id'] ?? userData?['user_id'];
  }

  // Get user's profile image URL
  static Future<String?> getProfileImageUrl() async {
    final userData = await getCurrentUserData();
    return userData?['profile_image_url'];
  }

  // Get user's bio
  static Future<String?> getUserBio() async {
    final userData = await getCurrentUserData();
    return userData?['bio'];
  }

  // Get user's location
  static Future<String?> getUserLocation() async {
    final userData = await getCurrentUserData();
    return userData?['location'];
  }

  // Get user's phone number
  static Future<String?> getUserPhoneNumber() async {
    final userData = await getCurrentUserData();
    return userData?['phone_number'];
  }

  // Get user's gender
  static Future<String?> getUserGender() async {
    final userData = await getCurrentUserData();
    return userData?['gender'];
  }

  // Check if user is verified
  static Future<bool> isUserVerified() async {
    final userData = await getCurrentUserData();
    return userData?['is_verified'] ?? false;
  }

  // Check if user is online
  static Future<bool> isUserOnline() async {
    final userData = await getCurrentUserData();
    return userData?['is_online'] ?? false;
  }

  // Update user data
  static Future<void> updateUserData(Map<String, dynamic> newData) async {
    final currentData = await getCurrentUserData();
    if (currentData != null) {
      final updatedData = {...currentData, ...newData};
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, json.encode(updatedData));
      
      // Update in-memory cache
      _currentUserData = updatedData;
      
      print('=== USER DATA UPDATED ===');
      print('Updated Data: $updatedData');
      print('=========================');
    }
  }

  // Fetch advertiser profile from API
  static Future<Map<String, dynamic>?> fetchAdvertiserProfile(int advertiserId) async {
    try {
      print('=== FETCHING ADVERTISER PROFILE ===');
      print('Advertiser ID: $advertiserId');
      print('===================================');

      final accessToken = await getAccessToken();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/advertisers/$advertiserId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      );

      print('=== ADVERTISER PROFILE RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('===================================');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle different response structures
        Map<String, dynamic> advertiserData;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('advertiser')) {
            advertiserData = responseData['advertiser'];
          } else if (responseData.containsKey('data')) {
            advertiserData = responseData['data'];
          } else {
            advertiserData = responseData;
          }
        } else {
          print('Unexpected response format');
          return null;
        }

        print('=== PARSED ADVERTISER DATA ===');
        print('Advertiser Data: $advertiserData');
        print('==============================');

        return advertiserData;
      } else {
        print('Failed to fetch advertiser profile: ${response.statusCode}');
        print('Error body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception while fetching advertiser profile: $e');
      return null;
    }
  }

  // Fetch user profile from API
  static Future<Map<String, dynamic>?> fetchUserProfile(int userId) async {
    try {
      print('=== FETCHING USER PROFILE ===');
      print('User ID: $userId');
      print('=============================');

      final accessToken = await getAccessToken();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      );

      print('=== USER PROFILE RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=============================');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle different response structures
        Map<String, dynamic> userData;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('user')) {
            userData = responseData['user'];
          } else if (responseData.containsKey('data')) {
            userData = responseData['data'];
          } else {
            userData = responseData;
          }
        } else {
          print('Unexpected response format');
          return null;
        }

        print('=== PARSED USER DATA ===');
        print('User Data: $userData');
        print('========================');

        return userData;
      } else {
        print('Failed to fetch user profile: ${response.statusCode}');
        print('Error body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception while fetching user profile: $e');
      return null;
    }
  }
}