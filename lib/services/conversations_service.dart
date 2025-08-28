import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';

class ConversationsService {
  static Future<Map<String, dynamic>> getOrCreateWithAdvertiser(int advertiserId) async {
    final url = '${ApiConfig.api}/conversations/with-advertiser/$advertiserId';
    return ApiClient.postJson(url, {}, auth: true);
  }

  static Future<List<Map<String, dynamic>>> list({int page = 1, int perPage = 20}) async {
    final url = '${ApiConfig.api}/conversations/?page=$page&per_page=$perPage';
    final data = await ApiClient.getJson(url, auth: true);
    if (data is List) return (data as List).cast<Map<String, dynamic>>();
    if (data['data'] is List) return (data['data'] as List).cast<Map<String, dynamic>>();
    return [];
  }

  static Future<List<Map<String, dynamic>>> getMessages(int conversationId, {int page = 1, int perPage = 50}) async {
    final url = '${ApiConfig.api}/messages/conversation/$conversationId?page=$page&per_page=$perPage';
    final data = await ApiClient.getJson(url, auth: true);
    if (data is List) return (data as List).cast<Map<String, dynamic>>();
    if (data['data'] is List) return (data['data'] as List).cast<Map<String, dynamic>>();
    return [];
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required int senderId,
    required String content,
  }) async {
    final body = {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
    };
    final url = '${ApiConfig.api}/messages/';
    return ApiClient.postJson(url, body, auth: true);
  }
}

