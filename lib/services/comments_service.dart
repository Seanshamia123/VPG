// lib/services/comments_service.dart
import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';

class CommentsService {
  static Future<List<Map<String, dynamic>>> fetchPostComments(int postId, {int page = 1, int perPage = 10}) async {
    final url = '${ApiConfig.api}/comments/target/post/$postId?page=$page&per_page=$perPage';
    final data = await ApiClient.getJson(url, auth: true);
    if (data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    // Some backends return list directly; ApiClient wraps as {'data': list}
    return [];
  }

  static Future<Map<String, dynamic>> addPostComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    final body = <String, dynamic>{
      'target_type': 'post',
      'target_id': postId,
      'content': content,
      if (parentCommentId != null) 'parent_comment_id': parentCommentId,
    };
    final url = '${ApiConfig.api}/comments/';
    return ApiClient.postJson(url, body, auth: true);
  }
}

