// lib/models/post.dart
class Post {
  final int id;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;
  final Advertiser advertiser;
  final int likeCount;
  final bool likedByMe;

  Post({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
    required this.advertiser,
    this.likeCount = 0,
    this.likedByMe = false,
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
      likeCount: (json['likes_count'] is int)
          ? json['likes_count'] as int
          : int.tryParse('${json['likes_count'] ?? 0}') ?? 0,
      likedByMe: (json['liked_by_me'] as bool?) ?? false,
    );
  }
}

class Advertiser {
  final int id;
  final String name;
  final String username;
  final String? city;
  final String? country;
  final String? profileImageUrl;

  Advertiser({
    required this.id,
    required this.name,
    required this.username,
    this.city,
    this.country,
    this.profileImageUrl,
  });

  factory Advertiser.fromJson(Map<String, dynamic> json) {
    return Advertiser(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Advertiser',
      username: json['username'] as String? ?? 'unknown',
      city: json['city'] as String?,
      country: json['country'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }
}
