import 'package:escort/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:escort/services/comments_service.dart';
import 'package:escort/services/user_session.dart';

class CommentInput extends StatefulWidget {
  final int? postId; // when provided, submit comment to backend
  final VoidCallback? onSubmitted;
  const CommentInput({super.key, this.postId, this.onSubmitted});

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final marginPadding = screenWidth < 600 ? 16.0 : 24.0;
    final avatarRadius = screenWidth < 600 ? 16.0 : 20.0;

    return Container(
      margin: EdgeInsets.all(marginPadding),
      padding: EdgeInsets.all(marginPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundImage: const NetworkImage(
              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=40&h=40&fit=crop&crop=face',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submitting
                          ? null
                          : () async {
                              final text = _controller.text.trim();
                              if (text.isEmpty) return;
                              if (widget.postId == null) {
                                widget.onSubmitted?.call();
                                _controller.clear();
                                return;
                              }
                              setState(() => _submitting = true);
                              try {
                                final token = await UserSession.getAccessToken();
                                if (token == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please login to comment')),
                                  );
                                } else {
                                  await CommentsService.addPostComment(postId: widget.postId!, content: text);
                                  widget.onSubmitted?.call();
                                  _controller.clear();
                                }
                              } catch (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to post comment')),
                                );
                              } finally {
                                if (mounted) setState(() => _submitting = false);
                              }
                            },
                      child: const Text(
                        'Post',
                        style: TextStyle(color: Colors.white),
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
/// Component: Comment Input
