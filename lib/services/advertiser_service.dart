// lib/services/advertiser_service.dart
import 'dart:convert';

import 'package:escort/services/api_config.dart';
import 'package:escort/services/api_client.dart';
import 'package:escort/services/user_session.dart';
import 'package:http/http.dart' as http;

class AdvertiserService {
  // Use consistent base URL from ApiConfig
  static String get baseUrl => ApiConfig.api;

  static Future<List<Map<String, dynamic>>> fetchAdvertisers({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final url = '$baseUrl/api/advertisers/?page=$page&per_page=$perPage';
      final data = await ApiClient.getJson(url, auth: false);
      
      // Handle new standardized response format
      if (data['items'] is List) {
        return (data['items'] as List).cast<Map<String, dynamic>>();
      }
      
      // Fallback for older formats
      if (data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      if (data is List) {
        return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching advertisers: $e');
      return [];
    }
  }

  /// Fetch advertiser profile by ID with proper error handling
  static Future<Map<String, dynamic>?> fetchAdvertiserById(int advertiserId) async {
    try {
      print('=== FETCHING ADVERTISER BY ID ===');
      print('Advertiser ID: $advertiserId');
      print('URL: $baseUrl/api/advertisers/$advertiserId');
      
      final url = '$baseUrl/api/advertisers/$advertiserId';
      
      // Use consistent error handling approach
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Advertiser not found');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
      
    } catch (e) {
      print('Error fetching advertiser by ID: $e');
      throw Exception('Failed to load advertiser profile: $e');
    }
  }

  /// Fetch posts by advertiser ID using the correct endpoint
  static Future<List<Map<String, dynamic>>> fetchAdvertiserPosts(int advertiserId) async {
    try {
      print('=== FETCHING POSTS BY ADVERTISER ID ===');
      print('Advertiser ID: $advertiserId');
      
      // Use the correct endpoint pattern
      final url = '$baseUrl/api/advertisers/$advertiserId/posts';
      print('URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<Map<String, dynamic>> posts = [];
        
        // Handle the response structure
        if (data['posts'] is List) {
          posts = (data['posts'] as List).cast<Map<String, dynamic>>();
        } else if (data['items'] is List) {
          posts = (data['items'] as List).cast<Map<String, dynamic>>();
        } else if (data['data'] is List) {
          posts = (data['data'] as List).cast<Map<String, dynamic>>();
        } else if (data is List) {
          posts = (data as List).cast<Map<String, dynamic>>();
        }
        
        print('Extracted ${posts.length} posts');
        return posts;
        
      } else if (response.statusCode == 404) {
        print('Advertiser or posts not found');
        return [];
      } else {
        print('Server error: ${response.statusCode}');
        return [];
      }
      
    } catch (e) {
      print('Error fetching advertiser posts: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> search(
    String query, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      // Build URL with query parameters - handle empty query gracefully
      final Map<String, String> params = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      
      // Only add query parameter if it's not empty
      if (query.trim().isNotEmpty) {
        params['q'] = query.trim();
      }
      
      final uri = Uri.parse('$baseUrl/api/advertisers/search')
          .replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['items'] is List) {
          return (data['items'] as List).cast<Map<String, dynamic>>();
        }
        if (data['data'] is List) {
          return (data['data'] as List).cast<Map<String, dynamic>>();
        }
        
        return [];
      } else {
        print('Search failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error searching advertisers: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchWithFilters({
    String? query,
    String? gender,
    String? location,
    bool verifiedOnly = false,
    bool onlineOnly = false,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      // Build query parameters
      final Map<String, String> params = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      // Only add parameters if they have values
      if (query != null && query.trim().isNotEmpty) {
        params['q'] = query.trim();
      }
      if (gender != null && gender.trim().isNotEmpty) {
        params['gender'] = gender.trim().toLowerCase();
      }
      if (location != null && location.trim().isNotEmpty) {
        params['location'] = location.trim();
      }
      if (verifiedOnly) {
        params['verified_only'] = 'true';
      }
      if (onlineOnly) {
        params['online_only'] = 'true';
      }

      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl/api/advertisers/search/filtered')
          .replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        
        return items.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id']?.toString() ?? '0',
            'name': item['name']?.toString() ?? 'Unknown',
            'username': item['username']?.toString() ?? 'unknown',
            'location': item['location']?.toString() ?? '',
            'gender': item['gender']?.toString() ?? '',
            'profile_image_url': item['profile_image_url']?.toString() ?? '',
            'is_verified': item['is_verified'] == true,
            'is_online': item['is_online'] == true,
            'distance': item['distance']?.toString() ?? '-- km',
            'bio': item['bio']?.toString() ?? '',
          };
        }).toList();
      } else if (response.statusCode == 401) {
        // Handle authentication error
        await UserSession.clearSession();
        throw Exception('Authentication required');
      } else {
        print('Search with filters failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error searching advertisers with filters: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getById(int id) async {
    try {
      final url = '$baseUrl/api/advertisers/$id';
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        print('Error fetching advertiser: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching advertiser by ID: $e');
      return null;
    }
  }

  /// Quick search for autocomplete suggestions
  static Future<List<Map<String, dynamic>>> getSearchSuggestions(
    String query, {
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) return [];
    
    return await searchWithFilters(
      query: query,
      perPage: limit,
    );
  }

  /// Get popular/trending advertisers
  static Future<List<Map<String, dynamic>>> getTrendingAdvertisers({
    int limit = 10,
  }) async {
    return await searchWithFilters(
      verifiedOnly: true,
      onlineOnly: true,
      perPage: limit,
    );
  }

  // Helper methods
  static Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      final token = await UserSession.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      print('Error getting auth token: $e');
    }

    return headers;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>> updateProfile(
    int advertiserId, {
    String? name,
    String? phoneNumber,
    String? location,
    String? bio,
    String? profileImageUrl,
    bool? isOnline,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (location != null) 'location': location,
      if (bio != null) 'bio': bio,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (isOnline != null) 'is_online': isOnline,
    };
    return ApiClient.putJson(
      '${ApiConfig.api}/advertisers/$advertiserId',
      body,
      auth: true,
    );
  }

  static Future<String?> uploadAvatarBase64(String base64Image, {String folder = 'vpg/advertisers'}) async {
    final data = await ApiClient.postJson(
      '${ApiConfig.api}/posts/upload-image',
      {
        'image': base64Image,
        'folder': folder,
      },
      auth: true,
    );
    if ((data['statusCode'] ?? 0) >= 200 && (data['statusCode'] ?? 0) < 300) {
      final url = (data['image_url'] ?? data['data']?['image_url'])?.toString();
      return (url != null && url.isNotEmpty) ? url : null;
    }
    return null;
  }
}

/// Service for handling post likes - used by AdvertiserPublicProfileScreen
class PostLikesService {
  static Future<Map<String, dynamic>> like(int postId) async {
    try {
      final response = await ApiClient.postJson(
        '${ApiConfig.api}/api/posts/$postId/like',
        {},
        auth: true,
      );
      return response;
    } catch (e) {
      print('Error liking post: $e');
      throw Exception('Failed to like post');
    }
  }

  static Future<Map<String, dynamic>> unlike(int postId) async {
    try {
      final response = await ApiClient.deleteJson(
        '${ApiConfig.api}/api/posts/$postId/like',
        auth: true,
      );
      return response;
    } catch (e) {
      print('Error unliking post: $e');
      throw Exception('Failed to unlike post');
    }
  }
}

/// Service for handling comments - used by AdvertiserPublicProfileScreen
class CommentsService {
  static Future<List<Map<String, dynamic>>> fetchPostComments(
    int postId, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final url = '${ApiConfig.api}/api/posts/$postId/comments?page=$page&per_page=$perPage';
      final data = await ApiClient.getJson(url, auth: true);
      
      if (data['items'] is List) {
        return (data['items'] as List).cast<Map<String, dynamic>>();
      }
      if (data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      if (data is List) {
        return (data as List).cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  // In your advertiser_service.dart, update the CommentsService.addPostComment method:

static Future<Map<String, dynamic>> addPostComment({
  required int postId,
  required String content,
}) async {
  try {
    print('=== ADDING COMMENT DEBUG ===');
    print('Post ID: $postId');
    print('Content: $content');
    
    final response = await ApiClient.postJson(
      '${ApiConfig.api}/api/posts/$postId/comments',
      {'content': content.trim()},
      auth: true,
    );
    
    print('Comment added successfully: $response');
    return response;
  } catch (e) {
    print('Error adding comment: $e');
    throw Exception('Failed to add comment: $e');
  }
}
}

// /// Service for handling conversations/chat - used by AdvertiserPublicProfileScreen
// class ConversationsService {
//   static Future<Map<String, dynamic>?> createOrGetConversation({
//     required int participantId,
//   }) async {
//     try {
//       final response = await ApiClient.postJson(
//         '${ApiConfig.api}/conversations',
//         {'participant_id': participantId},
//         auth: true,
//       );
//       return response;
//     } catch (e) {
//       print('Error creating conversation: $e');
//       throw Exception('Failed to create conversation');
//     }
//   }
// }