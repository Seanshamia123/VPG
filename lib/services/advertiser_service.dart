// lib/services/advertiser_service.dart
import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';

class AdvertiserService {
  static Future<List<Map<String, dynamic>>> fetchAdvertisers({
    int page = 1,
    int perPage = 10,
  }) async {
    final url = '${ApiConfig.api}/advertisers/?page=$page&per_page=$perPage';
    final data = await ApiClient.getJson(url, auth: false);
    // New standardized response: { items: [...], total, pages, current_page }
    if (data['items'] is List) {
      return (data['items'] as List).cast<Map<String, dynamic>>();
    }
    // Back-compat fallbacks
    if (data['data'] is List) return (data['data'] as List).cast<Map<String, dynamic>>();
    if (data is List) return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  }
}
