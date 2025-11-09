import 'dart:convert';
import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

// Remove the old conditional import that caused FileReader to be unresolved.
// ...existing code...

// Add conditional import for platform-specific file helper
import 'package:escort/services/platform_file_io.dart'
  if (dart.library.html) 'package:escort/services/platform_file_web.dart'
  as platform_file;

class ConversationsService {
  /// Get or create a conversation with an advertiser
  static Future<Map<String, dynamic>> getOrCreateWithAdvertiser(
    int advertiserId,
  ) async {
    try {
      final url =
          '${ApiConfig.api}/conversations/with-advertiser/$advertiserId';
      print('[ConversationsService] POST to: $url');
      
      final response = await ApiClient.postJson(url, <String, dynamic>{}, auth: true);
      
      print('[ConversationsService] Response: $response');
      
      if (response is Map<String, dynamic>) {
        return response;
      }
      
      throw Exception('Invalid response format from server');
    } catch (e) {
      print('[ConversationsService] Error: $e');
      rethrow;
    }
  }

  /// Get all conversations for current user
  static Future<List<Map<String, dynamic>>> list({
    int page = 1,
    int perPage = 20,
  }) async {
    final url =
        '${ApiConfig.api}/conversations/?page=$page&per_page=$perPage';
    final data = await ApiClient.getJson(url, auth: true);
    if (data is List) {
      return (data as List).cast<Map<String, dynamic>>();
    }
    if (data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Get messages for a conversation
  static Future<List<Map<String, dynamic>>> getMessages(
    int conversationId, {
    int page = 1,
    int perPage = 50,
  }) async {
    final url =
        '${ApiConfig.api}/messages/conversation/$conversationId?page=$page&per_page=$perPage';
    
    print('[ConversationsService] Getting messages from: $url');
    
    final data = await ApiClient.getJson(url, auth: true);
    
    print('[ConversationsService] Messages response type: ${data.runtimeType}');
    
    if (data is Map<String, dynamic>) {
      if (data['messages'] is List) {
        print('[ConversationsService] Found ${(data['messages'] as List).length} messages');
        return (data['messages'] as List).cast<Map<String, dynamic>>();
      }
    }
    
    if (data is List) {
      print('[ConversationsService] Direct list with ${data.length} messages');
      return (data as List).cast<Map<String, dynamic>>();
    }
    
    if (data['data'] is List) {
      print('[ConversationsService] Found ${(data['data'] as List).length} messages in data key');
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    
    print('[ConversationsService] No messages found in response');
    return [];
  }

  /// Send a text message to a conversation
  static Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required int senderId,
    required String senderType,
    required String content,
  }) async {
    String normalizedType = _normalizeSenderType(senderType);
    
    final Map<String, dynamic> body = {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_type': normalizedType,
      'content': content,
      'message_type': 'text',
    };
    final url = '${ApiConfig.api}/messages/';
    
    print('[ConversationsService] ===== SENDING TEXT MESSAGE =====');
    print('[ConversationsService] URL: $url');
    print('[ConversationsService] Body: $body');
    
    try {
      final response = await ApiClient.postJson(url, body, auth: true);
      print('[ConversationsService] ===== MESSAGE SENT SUCCESSFULLY =====');
      return response;
    } catch (e, stackTrace) {
      print('[ConversationsService] ===== ERROR SENDING MESSAGE =====');
      print('[ConversationsService] Error: $e');
      print('[ConversationsService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Send a media message (image, video, or audio) - WEB COMPATIBLE VERSION
  static Future<Map<String, dynamic>> sendMediaMessage({
    required int conversationId,
    required int senderId,
    required String senderType,
    required dynamic file, // Can be File (mobile) or html.File (web)
    required String mediaType,
    String content = '',
  }) async {
    try {
      String normalizedType = _normalizeSenderType(senderType);
      
      final url = '${ApiConfig.api}/messages/';
      
      print('[ConversationsService] ===== SENDING MEDIA MESSAGE =====');
      print('[ConversationsService] URL: $url');
      print('[ConversationsService] Media Type: $mediaType');
      print('[ConversationsService] Platform: ${kIsWeb ? "Web" : "Native"}');
      print('[ConversationsService] Sender: $normalizedType:$senderId');
      
      // Get auth token
      final token = await ApiClient.getAccessToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add form fields
      request.fields['conversation_id'] = conversationId.toString();
      request.fields['sender_id'] = senderId.toString();
      request.fields['sender_type'] = normalizedType;
      request.fields['message_type'] = mediaType;
      if (content.isNotEmpty) {
        request.fields['content'] = content;
      }
      
      // Add file - WEB vs NATIVE handling
      http.MultipartFile multipartFile;
      
      if (kIsWeb) {
        // WEB: Use bytes from html.File via helper
        print('[ConversationsService] Using web file upload');
        final webFile = file; // dynamic html.File at runtime
        final webData = await platform_file.readFileAsBytes(webFile);
        final bytes = webData['bytes'] as Uint8List;
        final filename = webData['name'] as String;
        
        // Determine MIME type from filename
        final mimeType = lookupMimeType(filename) ?? 'application/octet-stream';
        final mimeTypeParts = mimeType.split('/');
        
        print('[ConversationsService] File name: $filename');
        print('[ConversationsService] File size: ${bytes.length} bytes');
        print('[ConversationsService] MIME Type: $mimeType');
        
        multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        );
      } else {
        // NATIVE: Use file path
        print('[ConversationsService] Using native file upload');
        final nativeFile = file; // dynamic; expects an object with .path
        final filePath = nativeFile.path;
        
        final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
        final mimeTypeParts = mimeType.split('/');
        
        print('[ConversationsService] File Path: $filePath');
        print('[ConversationsService] MIME Type: $mimeType');
        
        multipartFile = await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        );
      }
      
      request.files.add(multipartFile);
      
      // Send request
      print('[ConversationsService] Sending multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('[ConversationsService] Response Status: ${response.statusCode}');
      print('[ConversationsService] Response Body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('[ConversationsService] ===== MEDIA MESSAGE SENT SUCCESSFULLY =====');
        
        // Parse JSON response
        final jsonResponse = ApiClient.parseResponse(response);
        return jsonResponse as Map<String, dynamic>;
      } else {
        throw Exception('Failed to send media message: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('[ConversationsService] ===== ERROR SENDING MEDIA MESSAGE =====');
      print('[ConversationsService] Error: $e');
      print('[ConversationsService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Upload media file without sending a message (for pre-upload) - WEB COMPATIBLE
  static Future<Map<String, dynamic>> uploadMedia({
    required dynamic file,
    required String mediaType,
  }) async {
    try {
      final url = '${ApiConfig.api}/messages/upload';
      
      print('[ConversationsService] ===== UPLOADING MEDIA =====');
      print('[ConversationsService] URL: $url');
      print('[ConversationsService] Media Type: $mediaType');
      print('[ConversationsService] Platform: ${kIsWeb ? "Web" : "Native"}');
      
      // Get auth token
      final token = await ApiClient.getAccessToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add form fields
      request.fields['media_type'] = mediaType;
      
      // Add file - WEB vs NATIVE handling
      http.MultipartFile multipartFile;
      
      if (kIsWeb) {
        // WEB: Use bytes
        final webFile = file; // dynamic html.File at runtime
        final webData = await platform_file.readFileAsBytes(webFile);
        final bytes = webData['bytes'] as Uint8List;
        final filename = webData['name'] as String;
        final mimeType = lookupMimeType(filename) ?? 'application/octet-stream';
        final mimeTypeParts = mimeType.split('/');
        
        multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        );
      } else {
        // NATIVE: Use file path
        final nativeFile = file; // dynamic; expects an object with .path
        final mimeType = lookupMimeType(nativeFile.path) ?? 'application/octet-stream';
        final mimeTypeParts = mimeType.split('/');
        
        multipartFile = await http.MultipartFile.fromPath(
          'file',
          nativeFile.path,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        );
      }
      
      request.files.add(multipartFile);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        print('[ConversationsService] ===== MEDIA UPLOADED SUCCESSFULLY =====');
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse as Map<String, dynamic>;
      } else {
        throw Exception('Failed to upload media: ${response.statusCode}');
      }
    } catch (e) {
      print('[ConversationsService] Error uploading media: $e');
      rethrow;
    }
  }

  /// Normalize sender type to match API expectations
  static String _normalizeSenderType(String type) {
    final normalized = type.toLowerCase();
    if (normalized == 'advertiser' || 
        normalized == 'escort' || 
        normalized == 'provider') {
      return 'advertiser';
    }
    return 'user';
  }

  /// Mark all messages in a conversation as read
  static Future<Map<String, dynamic>> markConversationAsRead(
    int conversationId,
  ) async {
    final url =
        '${ApiConfig.api}/messages/conversation/$conversationId/mark-read';
    final Map<String, dynamic> body = <String, dynamic>{};
    return ApiClient.postJson(url, body, auth: true);
  }

  /// Get a specific conversation by ID
  static Future<Map<String, dynamic>> getConversation(
    int conversationId,
  ) async {
    final url = '${ApiConfig.api}/conversations/$conversationId';
    return ApiClient.getJson(url, auth: true);
  }

  /// Delete a conversation
  static Future<void> deleteConversation(int conversationId) async {
    final url = '${ApiConfig.api}/conversations/$conversationId';
    await ApiClient.deleteJson(url, auth: true);
  }
}