// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:escort/config/api_config.dart';

class AuthService {
  static String get baseUrl => ApiConfig.auth;
  
  // Register User
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String location,
    required String gender,
  }) async {
    try {
      final requestData = {
        'username': username,
        'name': name,
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
        'location': location,
        'gender': gender,
      };

      // Debug: Print the request data
      print('=== USER REGISTRATION REQUEST ===');
      print('URL: $baseUrl/register/user');
      print('Request Data: ${json.encode(requestData)}');
      print('================================');

      final response = await http.post(
        Uri.parse('$baseUrl/register/user'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      // Debug: Print the response
      print('=== USER REGISTRATION RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');
      print('==================================');

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? responseData['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('Error in registerUser: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Register Advertiser
  static Future<Map<String, dynamic>> registerAdvertiser({
    required String username,
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String location,
    required String gender,
    String? bio,
  }) async {
    try {
      Map<String, dynamic> requestData = {
        'username': username,
        'name': name,
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
        'location': location,
        'gender': gender,
      };

      if (bio != null && bio.isNotEmpty) {
        requestData['bio'] = bio;
      }

      // Debug: Print the request data
      print('=== ADVERTISER REGISTRATION REQUEST ===');
      print('URL: $baseUrl/register/advertiser');
      print('Request Data: ${json.encode(requestData)}');
      print('Headers: Content-Type: application/json');
      print('=======================================');

      final response = await http.post(
        Uri.parse('$baseUrl/register/advertiser'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      // Debug: Print the response details
      print('=== ADVERTISER REGISTRATION RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      print('Response Body Length: ${response.body.length}');
      print('========================================');

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // Enhanced error handling
        print('Registration failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message': responseData['message'] ?? responseData['error'] ?? 'Registration failed',
          'statusCode': response.statusCode, // Include status code for debugging
        };
      }
    } catch (e) {
      print('Exception in registerAdvertiser: $e');
      print('Exception type: ${e.runtimeType}');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Login
// Add this method to your existing AuthService class

static Future<Map<String, dynamic>> login({
  required String email,
  required String password,
  required String userType, // 'user' or 'advertiser'
}) async {
  final url = Uri.parse('$baseUrl/login');
  
  // Create the request body
  final requestBody = {
    'email': email.trim(),
    'password': password,
    'user_type': userType,
  };

  print('=== LOGIN REQUEST ===');
  print('URL: $url');
  print('Body: ${requestBody.toString()}');
  print('====================');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(requestBody),
    );

    print('=== LOGIN RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body: ${response.body}');
    print('======================');

    // Parse the response
    Map<String, dynamic> responseData;
    try {
      responseData = json.decode(response.body);
    } catch (jsonError) {
      print('JSON parsing error: $jsonError');
      throw Exception('Invalid response format from server');
    }

    // Add status code to response data for better error handling
    responseData['statusCode'] = response.statusCode;

    // Check if login was successful
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success - check if we have the required fields
      if (responseData.containsKey('access_token')) {
        print('Login successful - tokens received');
        return responseData;
      } else {
        print('Login response missing access_token');
        throw Exception('Invalid response: missing access token');
      }
    } else {
      // Error response
      print('Login failed with status: ${response.statusCode}');
      
      // Return error response for proper error handling
      String errorMessage = 'Login failed';
      if (responseData.containsKey('message')) {
        errorMessage = responseData['message'];
      } else if (responseData.containsKey('error')) {
        errorMessage = responseData['error'].toString();
      }
      
      responseData['error'] = errorMessage;
      return responseData;
    }
  } catch (e) {
    print('=== LOGIN EXCEPTION ===');
    print('Exception Type: ${e.runtimeType}');
    print('Exception: $e');
    print('======================');
    
    // Return error response instead of throwing
    return {
      'success': false,
      'error': 'Network error: ${e.toString()}',
      'statusCode': 500,
    };
  }
}
  // Helper method to test connection
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.base}/health'), // Backend health endpoint
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print('Connection test - Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
