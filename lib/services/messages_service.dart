import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';

class MessagesService {
  /// Fetch recent conversations sorted by latest message (WhatsApp style)
  /// Returns conversations with unread count and last message preview
  static Future<List<Map<String, dynamic>>> fetchRecent({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final url =
          '${ApiConfig.api}/messages/recent?page=$page&per_page=$perPage';
      
      print('[MessagesService] Fetching recent conversations from: $url');
      
      final data = await ApiClient.getJson(url, auth: true);
      
      print('[MessagesService] Response type: ${data.runtimeType}');
      
      List<Map<String, dynamic>> conversations = [];
      
      // Handle different response formats
      if (data is List) {
        conversations = (data as List).cast<Map<String, dynamic>>();
      } else if (data is Map<String, dynamic>) {
        if (data['conversations'] is List) {
          conversations = (data['conversations'] as List).cast<Map<String, dynamic>>();
        } else if (data['data'] is List) {
          conversations = (data['data'] as List).cast<Map<String, dynamic>>();
        }
      }
      
      // Sort by last_message_at descending (newest first)
      conversations.sort((a, b) {
        final timeA = DateTime.tryParse((a['last_message_at'] ?? '').toString()) ?? DateTime(1970);
        final timeB = DateTime.tryParse((b['last_message_at'] ?? '').toString()) ?? DateTime(1970);
        return timeB.compareTo(timeA); // Newest first
      });
      
      print('[MessagesService] Fetched ${conversations.length} conversations');
      
      return conversations;
    } catch (e) {
      print('[MessagesService] Error fetching recent conversations: $e');
      rethrow;
    }
  }

  /// Get unread message count for all conversations
  static Future<int> getUnreadCount() async {
    try {
      final userId = await ApiClient.getJson(
        '${ApiConfig.api}/users/me',
        auth: true,
      );
      
      final uid = userId['id'];
      final url = '${ApiConfig.api}/messages/unread/$uid';
      
      final data = await ApiClient.getJson(url, auth: false);
      
      if (data is Map<String, dynamic>) {
        return data['unread_count'] as int? ?? 0;
      }
      
      return 0;
    } catch (e) {
      print('[MessagesService] Error getting unread count: $e');
      return 0;
    }
  }

  /// Get unread count for specific conversation
  static Future<int> getConversationUnreadCount(int conversationId) async {
    try {
      final url =
          '${ApiConfig.api}/messages/conversation/$conversationId/unread';
      
      final data = await ApiClient.getJson(url, auth: true);
      
      if (data is Map<String, dynamic>) {
        return data['unread_count'] as int? ?? 0;
      }
      
      return 0;
    } catch (e) {
      print('[MessagesService] Error getting conversation unread count: $e');
      return 0;
    }
  }

  /// Mark conversation as read
  static Future<void> markConversationAsRead(int conversationId) async {
    try {
      final url =
          '${ApiConfig.api}/messages/conversation/$conversationId/mark-read';
      
      await ApiClient.postJson(url, {}, auth: true);
      
      print('[MessagesService] Marked conversation $conversationId as read');
    } catch (e) {
      print('[MessagesService] Error marking conversation as read: $e');
    }
  }

  /// Search conversations by name or message content
  static Future<List<Map<String, dynamic>>> searchConversations(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final url =
          '${ApiConfig.api}/messages/search?q=$query&page=$page&per_page=$perPage';
      
      final data = await ApiClient.getJson(url, auth: true);
      
      List<Map<String, dynamic>> results = [];
      
      if (data is List) {
        results = (data as List).cast<Map<String, dynamic>>();
      } else if (data is Map<String, dynamic> && data['conversations'] is List) {
        results = (data['conversations'] as List).cast<Map<String, dynamic>>();
      }
      
      // Sort by last_message_at descending
      results.sort((a, b) {
        final timeA = DateTime.tryParse((a['last_message_at'] ?? '').toString()) ?? DateTime(1970);
        final timeB = DateTime.tryParse((b['last_message_at'] ?? '').toString()) ?? DateTime(1970);
        return timeB.compareTo(timeA);
      });
      
      return results;
    } catch (e) {
      print('[MessagesService] Error searching conversations: $e');
      return [];
    }
  }
}