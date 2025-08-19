// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:5000/auth';
  
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
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      final requestData = {
        'email': email,
        'password': password,
        'user_type': userType,
      };

      // Debug: Print the request data
      print('=== LOGIN REQUEST ===');
      print('URL: $baseUrl/login');
      print('Request Data: ${json.encode(requestData)}');
      print('====================');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      // Debug: Print the response
      print('=== LOGIN RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');
      print('======================');

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? responseData['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('Error in login: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Helper method to test connection
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'), // Assuming you have a health endpoint
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