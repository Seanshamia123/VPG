import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';

class PostLikesService {
  static Future<Map<String, dynamic>> like(int postId) async {
    final url = '${ApiConfig.api}/posts/$postId/like';
    return ApiClient.postJson(url, {}, auth: true);
  }

  static Future<Map<String, dynamic>> unlike(int postId) async {
    final url = '${ApiConfig.api}/posts/$postId/like';
    return ApiClient.deleteJson(url, auth: true);
  }
}

