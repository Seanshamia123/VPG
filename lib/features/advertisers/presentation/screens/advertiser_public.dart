/// Feature: Advertisers
/// Screen: AdvertiserPublicProfileScreen
///
/// Public profile view for an advertiser, including posts grid and actions.
import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/features/settings/presentation/screens/settings_screen.dart';
import 'package:escort/features/advertisers/presentation/screens/reviewspage.dart';
import 'package:escort/features/settings/presentation/screens/terms_and_conditions_screen.dart';
import 'package:escort/services/advertiser_service.dart';
import 'package:escort/services/user_session.dart';
import 'package:escort/features/auth/presentation/screens/login.dart';
// import 'package:escort/styles/app_size.dart';
// import 'package:escort/styles/post_cards_styling.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:escort/config/api_config.dart';
import 'package:escort/services/api_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:escort/features/advertisers/presentation/screens/post_detail.dart'; 


class AdvertiserPublicProfileScreen extends StatefulWidget {
  final int advertiserId;
  
  const AdvertiserPublicProfileScreen({
    Key? key,
    required this.advertiserId,
  }) : super(key: key);

  @override
  State<AdvertiserPublicProfileScreen> createState() => _AdvertiserPublicProfileScreenState();
}

class _AdvertiserPublicProfileScreenState extends State<AdvertiserPublicProfileScreen> {
  // Advertiser data
  Map<String, dynamic>? advertiserData;
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  
  // UI state
  final Set<int> _likedPostIds = <int>{};
  final Map<int, int> _postLikeCounts = <int, int>{};

  @override
  void initState() {
    super.initState();
    _loadAdvertiserProfile();
  }

  Future<void> _loadAdvertiserProfile() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // Fetch advertiser details
      final advertiserResult = await AdvertiserService.fetchAdvertiserById(widget.advertiserId);
      
      // Fetch advertiser's posts
      final postsResult = await AdvertiserService.fetchAdvertiserPosts(widget.advertiserId);
      
      setState(() {
        advertiserData = advertiserResult;
        posts = postsResult;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPostsByAdvertiserId(int advertiserId) async {
  try {
    final accessToken = await UserSession.getAccessToken();
    if (accessToken == null) return [];
    
    print('=== FETCHING POSTS BY ADVERTISER ID ===');
    print('Advertiser ID: $advertiserId');
    
    final res = await ApiClient.getJson(
      '${ApiConfig.api}/posts/advertiser/$advertiserId',
      auth: true,
    );
    
    print('API Response: $res');
    
    List<Map<String, dynamic>> posts = [];
    
    // Handle the response structure from the new endpoint
    if (res['posts'] is List) {
      posts = (res['posts'] as List).cast<Map<String, dynamic>>();
    } else if (res['data'] is List) {
      posts = (res['data'] as List).cast<Map<String, dynamic>>();
    } else if (res is List) {
      posts = (res as List).cast<Map<String, dynamic>>();
    }
    
    print('Extracted ${posts.length} posts');
    if (posts.isNotEmpty) {
      print('First post: ${posts[0]}');
    }
    
    return posts;
  } catch (e) {
    print('Error fetching posts by advertiser ID: $e');
    return [];
  }
}


  Future<void> _likePost(int postId) async {
    final currentlyLiked = _likedPostIds.contains(postId);
    
    try {
      if (currentlyLiked) {
        final res = await PostLikesService.unlike(postId);
        final cnt = int.tryParse('${res['likes_count'] ?? 0}') ?? 0;
        setState(() {
          _likedPostIds.remove(postId);
          _postLikeCounts[postId] = cnt;
        });
      } else {
        final res = await PostLikesService.like(postId);
        final cnt = int.tryParse('${res['likes_count'] ?? 0}') ?? 0;
        setState(() {
          _likedPostIds.add(postId);
          _postLikeCounts[postId] = cnt;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openCommentsForPost(int postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _CommentsSheet(postId: postId),
      ),
    );
  }

  // Future<void> _startChat() async {
  //   try {
  //     // Create or get conversation with this advertiser
  //     final conversation = await ConversationsService.createOrGetConversation(
  //       participantId: widget.advertiserId,
  //     );
      
  //     if (conversation != null && conversation['id'] != null) {
  //       await Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => ChatScreen(
  //             conversationId: conversation['id'],
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to start chat: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: const Center(
          child: CircularProgressIndicator(color: Colors.yellow),
        ),
      );
    }

    if (hasError || advertiserData == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadAdvertiserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final name = advertiserData!['name'] ?? 'Unknown';
    final username = advertiserData!['username'] ?? '';
    final bio = advertiserData!['bio'] ?? '';
    final profileImage = advertiserData!['profile_image_url'] ?? '';
    final isVerified = advertiserData!['is_verified'] ?? false;
    final isOnline = advertiserData!['is_online'] ?? false;
    final location = advertiserData!['location'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: CustomScrollView(
        slivers: [
          // App bar with profile image background
          SliverAppBar(
            expandedHeight: 400,
            floating: false,
            pinned: true,
            backgroundColor: Colors.grey[900],
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    // Show options menu
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Profile image background
                  profileImage.isNotEmpty
                      ? Image.network(
                          profileImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.person,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Profile info at bottom
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Online indicator
                        if (isOnline)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Name with verification
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isVerified)
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                          ],
                        ),
                        // Bio
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            bio,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Location
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.grey[400],
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons
         
          // Posts header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Posts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${posts.length}',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // Posts grid
          posts.isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      final imageUrl = post['image_url'] ?? '';
                      final postId = post['id'] ?? 0;
                      final likesCount = _postLikeCounts[postId] ?? (post['likes_count'] ?? 0);
                      final isLiked = _likedPostIds.contains(postId) || (post['liked_by_me'] ?? false);
                      
                      return GestureDetector(
                        onTap: () {
                          _showPostDetail(post);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[800],
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                              // Like count overlay
                              if (likesCount > 0)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          color: isLiked ? Colors.red : Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '$likesCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
        ],
      ),
    );
  }

  void _showPostDetail(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _PostDetailDialog(
          post: post,
          onLike: () => _likePost(post['id']),
          onComment: () => _openCommentsForPost(post['id']),
          isLiked: _likedPostIds.contains(post['id']) || (post['liked_by_me'] ?? false),
          likesCount: _postLikeCounts[post['id']] ?? (post['likes_count'] ?? 0),
        ),
      ),
    );
  }
}

// Post detail dialog widget
class _PostDetailDialog extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final bool isLiked;
  final int likesCount;

  const _PostDetailDialog({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.isLiked,
    required this.likesCount,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = post['image_url'] ?? '';
    final caption = post['caption'] ?? '';
    
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image
          if (imageUrl.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          
          // Actions and caption
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Actions row
                Row(
                  children: [
                    IconButton(
                      onPressed: onLike,
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                      ),
                    ),
                    Text(
                      '$likesCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: onComment,
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                // Caption
                if (caption.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Comments bottom sheet
class _CommentsSheet extends StatefulWidget {
  final int postId;
  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  bool loading = true;
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await CommentsService.fetchPostComments(
        widget.postId,
        page: 1,
        perPage: 50,
      );
      if (!mounted) return;
      setState(() {
        comments = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    try {
      await CommentsService.addPostComment(
        postId: widget.postId,
        content: text,
      );
      _controller.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const Text(
                'Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Colors.yellow),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey[800], height: 1),
                    itemBuilder: (context, i) {
                      final c = comments[i];
                      final user = c['user'] as Map<String, dynamic>?;
                      final name = user != null
                          ? (user['name'] ?? user['username'] ?? 'User')
                                .toString()
                          : 'User';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey[800],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          (c['content'] ?? '').toString(),
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a comment',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            borderSide: BorderSide(color: Colors.yellow),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.yellow),
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
