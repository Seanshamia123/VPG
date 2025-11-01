import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';

class ConversationsService {
  /// Get or create a conversation with an advertiser
  /// Returns: {'id': int, 'conversation_id': int, ...}
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
  /// Returns messages with sender information and sender_type
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
      // If response has 'messages' key
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

  /// Send a message to a conversation
  /// Requires both sender_id and sender_type to distinguish between users and advertisers
  static Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required int senderId,
    required String senderType, // 'user' or 'advertiser'
    required String content,
  }) async {
    // Normalize sender type
    String normalizedType = _normalizeSenderType(senderType);
    
    final Map<String, dynamic> body = {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_type': normalizedType,
      'content': content,
    };
    final url = '${ApiConfig.api}/messages/';
    
    print('[ConversationsService] ===== SENDING MESSAGE =====');
    print('[ConversationsService] URL: $url');
    print('[ConversationsService] Body: $body');
    print('[ConversationsService] Auth: true');
    
    try {
      final response = await ApiClient.postJson(url, body, auth: true);
      print('[ConversationsService] ===== MESSAGE SENT SUCCESSFULLY =====');
      print('[ConversationsService] Response: $response');
      print('[ConversationsService] Sent by: $normalizedType:$senderId');
      return response;
    } catch (e, stackTrace) {
      print('[ConversationsService] ===== ERROR SENDING MESSAGE =====');
      print('[ConversationsService] Error: $e');
      print('[ConversationsService] Stack trace: $stackTrace');
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