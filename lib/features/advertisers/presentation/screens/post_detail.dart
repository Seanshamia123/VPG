/// Feature: Advertisers
/// Screen: PostDetailScreen (single post with comments/likes)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';
import 'package:escort/services/user_session.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Enhanced color palette constants
  static const Color goldColor = Color(0xFFFFD700);
  static const Color brightGold = Color(0xFFFFC107);
  static const Color blackColor = Color(0xFF000000);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color greyColor = Color(0xFF808080);
  static const Color darkGreyColor = Color(0xFF404040);

  late Map<String, dynamic> _postData;
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _likes = [];
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _postData = Map<String, dynamic>.from(widget.post);
    _isLiked = _postData['liked_by_me'] ?? false;
    _loadPostDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetails() async {
    try {
      await Future.wait([
        _loadComments(),
        _loadLikes(),
      ]);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading post details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      final response = await ApiClient.getJson(
        '${ApiConfig.api}/posts/${_postData['id']}/comments',
        auth: true,
      );

      if (response['comments'] != null) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(response['comments']);
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
    }
  }

  Future<void> _loadLikes() async {
    try {
      // You'll need to create this endpoint in your backend
      final response = await ApiClient.getJson(
        '${ApiConfig.api}/posts/${_postData['id']}/likes',
        auth: true,
      );

      if (response['likes'] != null) {
        setState(() {
          _likes = List<Map<String, dynamic>>.from(response['likes']);
        });
      }
    } catch (e) {
      print('Error loading likes: $e');
      // For now, create mock data if endpoint doesn't exist
      if (_postData['likes_count'] != null && _postData['likes_count'] > 0) {
        setState(() {
          _likes = [
            {
              'id': 1,
              'user_id': 1,
              'advertiser': {
                'id': 1,
                'name': 'user',
                'username': 'user'
              }
            }
          ];
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      final postId = _postData['id'];
      final wasLiked = _isLiked;

      // Optimistically update UI
      setState(() {
        _isLiked = !_isLiked;
        _postData['likes_count'] = (_postData['likes_count'] ?? 0) + (_isLiked ? 1 : -1);
      });

      if (wasLiked) {
        // Unlike
        await ApiClient.deleteJson(
          '${ApiConfig.api}/posts/$postId/like',
          auth: true,
        );
      } else {
        // Like
        await ApiClient.postJson(
          '${ApiConfig.api}/posts/$postId/like',
          {},
          auth: true,
        );
      }

      // Reload likes to get updated list
      await _loadLikes();
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _isLiked = !_isLiked;
        _postData['likes_count'] = (_postData['likes_count'] ?? 0) + (_isLiked ? 1 : -1);
      });
      _showErrorSnackBar('Failed to update like');
    }
  }

  Future<void> _postComment() async {
  if (_commentController.text.trim().isEmpty) return;

  setState(() {
    _isPostingComment = true;
  });

  try {
    final response = await ApiClient.postJson(
      '${ApiConfig.api}/comments/',
      {
        'target_type': 'post',
        'target_id': _postData['id'],
        'content': _commentController.text.trim(),
        'parent_comment_id': null, // Explicitly set to null for top-level comments
      },
      auth: true,
    );

    print('Comment response: $response'); // Debug log

    // Handle different response structures
    if (response['success'] == true || response['comment'] != null) {
      _commentController.clear();
      await _loadComments();
      _showSuccessSnackBar('Comment posted successfully!');
      
      // Scroll to bottom to show new comment
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else if (response['error'] != null) {
      _showErrorSnackBar(response['error']);
    } else {
      // If response structure is unexpected but no error
      _commentController.clear();
      await _loadComments();
      _showSuccessSnackBar('Comment posted successfully!');
    }
  } catch (e) {
    print('Comment posting error: $e'); // Debug log
    String errorMessage = 'Failed to post comment';
    
    // Handle specific error types
    if (e.toString().contains('400')) {
      errorMessage = 'Invalid comment data';
    } else if (e.toString().contains('401')) {
      errorMessage = 'You need to be logged in to comment';
    } else if (e.toString().contains('404')) {
      errorMessage = 'Post not found';
    } else if (e.toString().contains('500')) {
      errorMessage = 'Server error, please try again';
    }
    
    _showErrorSnackBar(errorMessage);
  } finally {
    setState(() {
      _isPostingComment = false;
    });
  }
}

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: blackColor),
            SizedBox(width: 12),
            Text(
              message,
              style: TextStyle(color: blackColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: goldColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: whiteColor),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showLikesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text(
              'Likes',
              style: TextStyle(
                color: blackColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: _likes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 60,
                        color: greyColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No likes yet',
                        style: TextStyle(
                          color: greyColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _likes.length,
                  itemBuilder: (context, index) {
                    final like = _likes[index];
                    final advertiser = like['advertiser'];
                    
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: goldColor.withOpacity(0.2),
                        child: Text(
                          (advertiser['name'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            color: blackColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        advertiser['name'] ?? 'Unknown User',
                        style: TextStyle(
                          color: blackColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '@${advertiser['username'] ?? 'unknown'}',
                        style: TextStyle(color: greyColor),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: goldColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: blackColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _postData['advertiser']?['username'] ?? 'Post',
          style: TextStyle(
            color: blackColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: blackColor),
            onPressed: () {
              // Show post options
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(goldColor),
              ),
            )
          : Column(
              children: [
                // Post content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post header
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: goldColor.withOpacity(0.2),
                                child: Text(
                                  (_postData['advertiser']?['name'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: blackColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _postData['advertiser']?['name'] ?? 'Unknown User',
                                      style: TextStyle(
                                        color: blackColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _formatTimeAgo(_postData['created_at']),
                                      style: TextStyle(
                                        color: greyColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Post image
                        Container(
                          width: double.infinity,
                          child: Image.network(
                            _postData['image_url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 300,
                                color: greyColor.withOpacity(0.2),
                                child: Center(
                                  child: Icon(
                                    Icons.image,
                                    color: greyColor,
                                    size: 60,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Post actions (like, comment, share)
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _toggleLike,
                                child: Icon(
                                  _isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: _isLiked ? Colors.red : blackColor,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 16),
                              Icon(
                                Icons.comment_outlined,
                                color: blackColor,
                                size: 28,
                              ),
                              SizedBox(width: 16),
                              Icon(
                                Icons.send_outlined,
                                color: blackColor,
                                size: 28,
                              ),
                              Spacer(),
                              Icon(
                                Icons.bookmark_border,
                                color: blackColor,
                                size: 28,
                              ),
                            ],
                          ),
                        ),

                        // Likes count
                        if ((_postData['likes_count'] ?? 0) > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: GestureDetector(
                              onTap: _showLikesDialog,
                              child: Text(
                                _getLikesText(),
                                style: TextStyle(
                                  color: blackColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),

                        // Post caption
                        if (_postData['caption'] != null && _postData['caption'].toString().isNotEmpty)
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${_postData['advertiser']?['username'] ?? 'user'} ',
                                    style: TextStyle(
                                      color: blackColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _postData['caption'],
                                    style: TextStyle(
                                      color: blackColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // View all comments text
                        if (_comments.length > 2)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: GestureDetector(
                              onTap: () {
                                // Scroll to comments section
                                _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Text(
                                'View all ${_comments.length} comments',
                                style: TextStyle(
                                  color: greyColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),

                        SizedBox(height: 8),

                        // Comments section
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return _buildCommentItem(comment);
                          },
                        ),

                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Comment input
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: whiteColor,
                    border: Border(
                      top: BorderSide(color: greyColor.withOpacity(0.3)),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: goldColor.withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            color: goldColor,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            enabled: !_isPostingComment,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(color: greyColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: greyColor.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: goldColor),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            style: TextStyle(color: blackColor),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _postComment(),
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isPostingComment ? null : _postComment,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _commentController.text.trim().isNotEmpty
                                  ? goldColor
                                  : greyColor.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: _isPostingComment
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(blackColor),
                                    ),
                                  )
                                : Icon(
                                    Icons.send,
                                    color: _commentController.text.trim().isNotEmpty
                                        ? blackColor
                                        : greyColor,
                                    size: 16,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final advertiser = comment['advertiser'];
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: goldColor.withOpacity(0.2),
            child: Text(
              (advertiser['name'] ?? 'U')[0].toUpperCase(),
              style: TextStyle(
                color: blackColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${advertiser['username'] ?? 'user'} ',
                        style: TextStyle(
                          color: blackColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: comment['content'] ?? '',
                        style: TextStyle(
                          color: blackColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(comment['created_at']),
                      style: TextStyle(
                        color: greyColor,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        // Reply to comment functionality
                      },
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: greyColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Like comment functionality
            },
            child: Icon(
              Icons.favorite_border,
              color: greyColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _getLikesText() {
    final likesCount = _postData['likes_count'] ?? 0;
    if (likesCount == 0) return '';
    
    if (_likes.isNotEmpty && likesCount > 0) {
      final firstLiker = _likes[0]['advertiser']['username'];
      if (likesCount == 1) {
        return 'Liked by $firstLiker';
      } else {
        final others = likesCount - 1;
        return 'Liked by $firstLiker and $others other${others == 1 ? '' : 's'}';
      }
    }
    
    return '$likesCount like${likesCount == 1 ? '' : 's'}';
  }

  String _formatTimeAgo(String? dateString) {
    if (dateString == null) return '';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }
}
