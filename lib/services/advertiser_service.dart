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

  static Future<List<Map<String, dynamic>>> search(String query, {int page = 1, int perPage = 10}) async {
    if (query.trim().isEmpty) return [];
    final url = '${ApiConfig.api}/advertisers/search?q='
        '${Uri.encodeQueryComponent(query)}&page=$page&per_page=$perPage';
    final data = await ApiClient.getJson(url, auth: false);
    if (data['items'] is List) {
      return (data['items'] as List).cast<Map<String, dynamic>>();
    }
    if (data['data'] is List) return (data['data'] as List).cast<Map<String, dynamic>>();
    return [];
  }

  static Future<Map<String, dynamic>?> getById(int id) async {
    final url = '${ApiConfig.api}/advertisers/$id';
    final data = await ApiClient.getJson(url, auth: false);
    if (data['statusCode'] != null && data['statusCode'] >= 400) return null;
    return data;
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
