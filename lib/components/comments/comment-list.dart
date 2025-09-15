import 'package:escort/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:escort/services/comments_service.dart';

class CommentList extends StatefulWidget {
  final int? postId; // when provided, fetch real comments for this post
  const CommentList({super.key, this.postId});

  @override
  State<CommentList> createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.postId == null) return [];
    try {
      return await CommentsService.fetchPostComments(widget.postId!, page: 1, perPage: 20);
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final comments = snapshot.data ?? [];

          // When no postId or no data, render the previous placeholders
          if (widget.postId == null || comments.isEmpty) {
            return Column(
              children: [
                _buildComment(
                  context,
                  avatar:
                      'https://images.unsplash.com/photo-1664575602554-2087b04935a5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3MzkyNDZ8MHwxfHNlYXJjaHwxfHx3b21hbnxlbnwwfHx8fDE3NTA1NDAxNDl8MA&ixlib=rb-4.1.0&q=80&w=1080',
                  username: 'sarah_johnson',
                  time: '2h',
                  content:
                      'This is absolutely stunning! The attention to detail is incredible. How long did this take you to create?',
                  likes: 24,
                  hasNested: true,
                ),
                _buildComment(
                  context,
                  avatar:
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=40&h=40&fit=crop&crop=face',
                  username: 'mike_creative',
                  time: '4h',
                  content:
                      'Amazing work! The color palette is perfect. Would love to see a tutorial on your process 🔥',
                  likes: 156,
                  isLiked: true,
                ),
                _buildComment(
                  context,
                  avatar:
                      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=40&h=40&fit=crop&crop=face',
                  username: 'emma_art',
                  time: '6h',
                  content:
                      'Incredible! This inspires me to keep pushing my own creative boundaries. Thank you for sharing! ✨',
                  likes: 42,
                ),
                SizedBox(height: horizontalPadding),
              ],
            );
          }

          // Map backend comments
          return Column(
            children: [
              for (final c in comments)
                _buildComment(
                  context,
                  avatar: '',
                  username: (c['user']?['username'] ?? c['user']?['name'] ?? 'user').toString(),
                  time: '',
                  content: (c['content'] ?? '').toString(),
                  likes: (c['likes_count'] ?? 0) as int,
                  hasNested: (c['replies'] is List) && (c['replies'] as List).isNotEmpty,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildComment(
    BuildContext context, {
    required String avatar,
    required String username,
    required String time,
    required String content,
    required int likes,
    bool isLiked = false,
    bool hasNested = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarRadius = screenWidth < 600 ? 16.0 : 20.0;
    final marginBottom = screenWidth < 600 ? 12.0 : 16.0;

    return Container(
      margin: EdgeInsets.only(bottom: marginBottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  backgroundColor: AppColors.darkBackgroundColor,
                  child: avatar.isEmpty
                      ? const Icon(Icons.person, color: Colors.white70)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.darkBackgroundColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: isLiked
                                  ? AppColors.primary
                                  : AppColors.grey,
                            ),
                            onPressed: () {},
                          ),
                          Text(
                            likes.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasNested)
            Padding(
              padding: const EdgeInsets.only(left: 52, right: 16, bottom: 16),
              child: Column(
                children: [
                  _buildNestedComment(
                    context,
                    avatar:
                        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=32&h=32&fit=crop&crop=face',
                    username: 'alex_design',
                    time: '1h',
                    content:
                        '@sarah_johnson Thanks! It took about 3 weeks of consistent work',
                    likes: 8,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNestedComment(
    BuildContext context, {
    required String avatar,
    required String username,
    required String time,
    required String content,
    required int likes,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarRadius = screenWidth < 600 ? 12.0 : 16.0;
    final marginBottom = screenWidth < 600 ? 8.0 : 12.0;

    return Container(
      margin: EdgeInsets.only(bottom: marginBottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            backgroundColor: AppColors.darkBackgroundColor,
            child: avatar.isEmpty
                ? const Icon(Icons.person, color: Colors.white70, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(fontSize: 10, color: AppColors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 12, color: AppColors.text),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: AppColors.grey,
                      ),
                      onPressed: () {},
                    ),
                    Text(
                      likes.toString(),
                      style: TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Reply',
                        style: TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
/// Component: Comment List
