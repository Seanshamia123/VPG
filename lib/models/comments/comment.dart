class Comment {
  final String avatar;
  final String username;
  final String time;
  final String content;
  final int likes;
  final bool isLiked;
  final List<Comment> replies;

  Comment({
    required this.avatar,
    required this.username,
    required this.time,
    required this.content,
    required this.likes,
    this.isLiked = false,
    this.replies = const [],
  });
}
