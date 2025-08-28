// lib/services/post_service.dart
// import 'dart:convert';
import 'package:escort/config/api_config.dart';
import 'package:escort/models/post.dart';
import 'package:escort/services/api_client.dart';

class PostService {
  static Future<List<Post>> fetchFeed({int page = 1, int perPage = 10}) async {
    final url = '${ApiConfig.api}/posts/?page=$page&per_page=$perPage';
    final data = await ApiClient.getJson(url, auth: true);

    // Backend may return {items:[...]}, raw list, or {posts:[...]}
    // Handle all gracefully
    List postsList;
    if (data['items'] is List) {
      postsList = data['items'] as List;
    } else if (data.containsKey('posts') && data['posts'] is List) {
      postsList = data['posts'] as List;
    } else if (data['data'] is List) {
      postsList =
          data['data']
              as List; // when response is a list, ApiClient wraps as {'data': list}
    } else if (data.values.any((v) => v is List)) {
      // Fallback: find the first list
      postsList = (data.values.firstWhere((v) => v is List) as List);
    } else {
      postsList = [];
    }

    return postsList.cast<Map<String, dynamic>>().map(Post.fromJson).toList();
  }
}
