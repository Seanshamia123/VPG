// lib/services/messages_service.dart
import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';

class MessagesService {
  static Future<List<Map<String, dynamic>>> fetchRecent({int page = 1, int perPage = 20}) async {
    final url = '${ApiConfig.api}/messages/recent?page=$page&per_page=$perPage';
    final data = await ApiClient.getJson(url, auth: true);
    if (data['conversations'] is List) {
      return (data['conversations'] as List).cast<Map<String, dynamic>>();
    }
    if (data['data'] is Map && data['data']['conversations'] is List) {
      return (data['data']['conversations'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}

