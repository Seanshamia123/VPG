// lib/models/post.dart
class Post {
  final int id;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;
  final Advertiser advertiser;

  Post({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
    required this.advertiser,
    this.caption,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      advertiser: Advertiser.fromJson(
        json['advertiser'] as Map<String, dynamic>,
      ),
    );
  }
}

class Advertiser {
  final int id;
  final String name;
  final String username;

  Advertiser({required this.id, required this.name, required this.username});

  factory Advertiser.fromJson(Map<String, dynamic> json) {
    return Advertiser(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Advertiser',
      username: json['username'] as String? ?? 'unknown',
    );
  }
}
