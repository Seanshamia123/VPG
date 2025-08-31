import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/screens/settings_screen.dart';
import 'package:escort/screens/shared_screens/reviewspage.dart';
import 'package:escort/screens/terms_and_conditions_screen.dart';
import 'package:escort/services/user_session.dart';
import 'package:escort/screens/shared_screens/login.dart';
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
import 'package:escort/screens/advertisers screens/post_detail.dart'; 

class AdvertiserProfile extends StatefulWidget {
  const AdvertiserProfile({super.key});

  @override
  State<AdvertiserProfile> createState() => _AdvertiserProfileState();
}

class _AdvertiserProfileState extends State<AdvertiserProfile> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _picker = ImagePicker();

  // Enhanced color palette constants
  static const Color goldColor = Color(0xFFFFD700);
  static const Color brightGold = Color(0xFFFFC107);
  static const Color blackColor = Color(0xFF000000);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color greyColor = Color(0xFF808080);
  static const Color darkGreyColor = Color(0xFF404040);

  // User data variables
  String userName = 'Loading...';
  String userEmail = '';
  String userBio =
      'Professional escort services with premium quality and discretion';
  String? profileImageUrl;
  String userLocation = '';
  bool isVerified = false;
  bool isOnline = false;
  bool isLoading = true;

  // Stats

  // int followersCount = 221;
  // int followingCount = 1025;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  late Future<List<Map<String, dynamic>>> _futureMyPosts = _fetchMyPostsWithFullData();

  // Updated method to fetch posts by advertiser ID using the new endpoint
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

// Method to fetch current user's posts using their advertiser ID
Future<List<Map<String, dynamic>>> _fetchMyPostsFullData() async {
  try {
    // Get current user's advertiser ID
    final userData = await UserSession.getCurrentUserData();
    final advertiserId = userData?['id'];
    
    if (advertiserId == null) {
      print('No advertiser ID found in user data');
      return [];
    }
    
    print('Fetching posts for current user (advertiser ID: $advertiserId)');
    return await _fetchPostsByAdvertiserId(advertiserId);
  } catch (e) {
    print('Error in _fetchMyPostsFullData: $e');
    return [];
  }
}

// Alternative: If you only have individual post endpoints and need to fetch multiple posts
Future<List<Map<String, dynamic>>> _fetchPostsByIds(List<int> postIds) async {
  try {
    final accessToken = await UserSession.getAccessToken();
    if (accessToken == null) return [];
    
    List<Map<String, dynamic>> posts = [];
    
    // Fetch each post individually
    for (int postId in postIds) {
      try {
        final res = await ApiClient.getJson(
          '${ApiConfig.api}/posts/$postId',
          auth: true,
        );
        
        if (res['data'] != null) {
          posts.add(res['data']);
        } else if (res['id'] != null) {
          // If the response is the post object directly
          posts.add(res);
        }
      } catch (e) {
        print('Error fetching post $postId: $e');
        // Continue with other posts even if one fails
      }
    }
    
    return posts;
  } catch (e) {
    print('Error fetching posts by IDs: $e');
    return [];
  }
}

// Updated method that returns full post objects instead of just image URLs
Future<List<Map<String, dynamic>>> _fetchMyPostsWithFullData() async {
  try {
    // Get current user's advertiser ID
    final userData = await UserSession.getCurrentUserData();
    final advertiserId = userData?['id'];
    
    if (advertiserId == null) {
      print('No advertiser ID found');
      return [];
    }
    
    return await _fetchPostsByAdvertiserId(advertiserId);
  } catch (e) {
    print('Error in _fetchMyPostsWithFullData: $e');
    return [];
  }
}

// For displaying in the grid (extracting image URLs from full post data)
Future<List<String>> _fetchMyPostImages() async {
  try {
    final posts = await _fetchMyPostsWithFullData();
    return posts
        .map((post) => (post['image_url'] ?? '').toString())
        .where((url) => url.isNotEmpty)
        .toList();
  } catch (e) {
    print('Error extracting image URLs: $e');
    return [];
  }
}

  Future<void> _loadUserData() async {
    try {
      // Load user data from session
      final userData = await UserSession.getCurrentUserData();

      if (userData != null) {
        setState(() {
          userName = userData['name'] ?? userData['username'] ?? 'Unknown User';
          userEmail = userData['email'] ?? '';
          userBio =
              userData['bio'] ??
              'Professional escort services with premium quality and discretion';
          profileImageUrl = userData['profile_image_url'];
          userLocation = userData['location'] ?? '';
          isVerified = userData['is_verified'] ?? false;
          isOnline = userData['is_online'] ?? false;
          isLoading = false;
        });

        print('=== USER DATA LOADED ===');
        print('Name: $userName');
        print('Email: $userEmail');
        print('Bio: $userBio');
        print('Profile Image: $profileImageUrl');
        print('Location: $userLocation');
        print('Verified: $isVerified');
        print('Online: $isOnline');
        print('========================');
      } else {
        print('No user data found in session');
        setState(() {
          userName = 'Guest User';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userName = 'Error Loading User';
        isLoading = false;
      });
    }
  }

  // Method to get profile image widget
  Widget _getProfileImage({required double radius, bool showBorder = true}) {
    Widget imageWidget;

    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      // Use network image if available
      imageWidget = CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(profileImageUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          print('Error loading profile image: $exception');
        },
      );
    } else {
      // Use a default user icon when no profile image
      imageWidget = CircleAvatar(
        radius: radius,
        backgroundColor: goldColor.withOpacity(0.15),
        child: Icon(Icons.person, color: goldColor, size: radius),
      );
    }

    if (showBorder) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isVerified ? brightGold : goldColor,
            width: isVerified ? 4 : 3,
          ),
        ),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  // Fixed "New" story highlight handler - this is the main entry point
  Future<void> _handleNewStoryTap() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMediaSelectionBottomSheet(),
    );
  }

  Widget _buildMediaSelectionBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: blackColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: greyColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),

            // Title
            Row(
              children: [
                Icon(Icons.add_circle, color: goldColor, size: 28),
                SizedBox(width: 12),
                Text(
                  'Create New Post',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: blackColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Choose how you want to add media',
              style: TextStyle(color: greyColor, fontSize: 16),
            ),
            SizedBox(height: 30),

            // Media options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEnhancedMediaOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  subtitle: 'Take photo/video',
                  onTap: () {
                    Navigator.pop(context);
                    _showCameraOptions();
                  },
                ),
                _buildEnhancedMediaOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  subtitle: 'Choose from gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _showGalleryOptions();
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedMediaOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: goldColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: goldColor.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: goldColor.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: goldColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: blackColor),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: blackColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: greyColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCameraOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Camera Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: blackColor,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: goldColor),
              ),
              title: Text('Take Photo'),
              subtitle: Text('Capture a new photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessMedia(ImageSource.camera, isVideo: false);
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.videocam, color: goldColor),
              ),
              title: Text('Record Video'),
              subtitle: Text('Record a new video'),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessMedia(ImageSource.camera, isVideo: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGalleryOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gallery Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: blackColor,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image, color: goldColor),
              ),
              title: Text('Select Photo'),
              subtitle: Text('Choose photo from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessMedia(ImageSource.gallery, isVideo: false);
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.video_library, color: goldColor),
              ),
              title: Text('Select Video'),
              subtitle: Text('Choose video from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessMedia(ImageSource.gallery, isVideo: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndProcessMedia(
    ImageSource source, {
    required bool isVideo,
  }) async {
    try {
      // Show loading
      _showLoadingDialog('Selecting media...');

      XFile? pickedFile;

      if (isVideo) {
        pickedFile = await _picker.pickVideo(
          source: source,
          maxDuration: Duration(minutes: 10),
        );
      } else {
        pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      }

      Navigator.pop(context); // Close loading dialog

      if (pickedFile != null) {
        String mediaPath;

        if (kIsWeb) {
          // On web, use the path directly (it's already a blob URL)
          mediaPath = pickedFile.path;
        } else {
          // On mobile/desktop, use the file path
          mediaPath = pickedFile.path;
        }

        if (isVideo) {
          // For video, go directly to post creation
          await _showPostCreationDialog(mediaPath, isVideo: true);
        } else {
          // For images, show editing options first
          await _showImageEditingOptions(mediaPath);
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error picking media: $e');
      _showErrorSnackBar('Error selecting media. Please try again.');
    }
  }

  Future<void> _showImageEditingOptions(String imagePath) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Image',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: blackColor,
              ),
            ),
            SizedBox(height: 20),

            // Image preview - FIXED FOR WEB
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: goldColor, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: kIsWeb
                    ? Image.network(
                        imagePath, // On web, imagePath will be a blob URL
                        fit: BoxFit.cover,
                      )
                    : Image.file(File(imagePath), fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEditOption(
                  icon: Icons.crop,
                  label: 'Crop Image',
                  onTap: () async {
                    Navigator.pop(context);
                    await _cropImage(imagePath);
                  },
                ),
                _buildEditOption(
                  icon: Icons.send,
                  label: 'Use As Is',
                  onTap: () async {
                    Navigator.pop(context);
                    await _showPostCreationDialog(imagePath, isVideo: false);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: goldColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: goldColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: goldColor, size: 28),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: blackColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cropImage(String imagePath) async {
    try {
      _showLoadingDialog('Opening image editor...');

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,

        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: goldColor,
            toolbarWidgetColor: blackColor,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            statusBarColor: goldColor,
            backgroundColor: whiteColor,
            activeControlsWidgetColor: goldColor,
            dimmedLayerColor: blackColor.withOpacity(0.8),
            cropFrameColor: goldColor,
            cropGridColor: goldColor.withOpacity(0.5),
          ),
          IOSUiSettings(
            title: 'Crop Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
          ),
        ],
      );

      Navigator.pop(context); // Close loading dialog

      if (croppedFile != null) {
        await _showPostCreationDialog(croppedFile.path, isVideo: false);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error cropping image: $e');
      _showErrorSnackBar('Error editing image. Using original image.');
      await _showPostCreationDialog(imagePath, isVideo: false);
    }
  }

  Future<void> _showPostCreationDialog(
    String filePath, {
    required bool isVideo,
  }) async {
    final TextEditingController captionController = TextEditingController();
    bool isPosting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    isVideo ? Icons.videocam : Icons.image,
                    color: goldColor,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Create Post",
                    style: TextStyle(
                      color: blackColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media preview - FIXED FOR WEB
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: goldColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: blackColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: isVideo
                            ? Container(
                                color: blackColor.withOpacity(0.1),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_circle_filled,
                                      size: 60,
                                      color: goldColor,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Video Ready",
                                      style: TextStyle(
                                        color: darkGreyColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : kIsWeb
                            ? Image.network(
                                filePath, // On web, filePath will be a blob URL
                                fit: BoxFit.cover,
                              )
                            : Image.file(File(filePath), fit: BoxFit.cover),
                      ),
                    ),
                    SizedBox(height: 25),

                    // Caption input
                    Text(
                      "Caption",
                      style: TextStyle(
                        color: blackColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: captionController,
                      maxLines: 3,
                      enabled: !isPosting,
                      decoration: InputDecoration(
                        hintText: "Write a caption for your post...",
                        hintStyle: TextStyle(color: greyColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: greyColor.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: goldColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      style: TextStyle(color: blackColor),
                    ),

                    if (isPosting) ...[
                      SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                goldColor,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Creating your post...',
                              style: TextStyle(color: greyColor, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: isPosting
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: greyColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: goldColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (captionController.text.trim().isEmpty) {
                              _showErrorSnackBar('Please add a caption');
                              return;
                            }

                            setState(() {
                              isPosting = true;
                            });

                            try {
                              await _createPostAPI(
                                filePath: filePath,
                                caption: captionController.text.trim(),
                                isVideo: isVideo,
                              );

                              Navigator.pop(dialogContext);
                              _showSuccessSnackBar(
                                'Post created successfully!',
                              );

                              // Refresh posts count
                            } catch (e) {
                              setState(() {
                                isPosting = false;
                              });
                              _showErrorSnackBar(
                                'Failed to create post. Please try again.',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            foregroundColor: blackColor,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Post",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  // FIXED: Updated API call to match your backend expectations
  Future<void> _createPostAPI({
    required String filePath,
    required String caption,
    required bool isVideo,
  }) async {
    try {
      print('=== CREATING POST API CALL ===');
      print('File Path: $filePath');
      print('Caption: $caption');
      print('Is Video: $isVideo');

      // Get access token
      final accessToken = await UserSession.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      String base64String;

      if (kIsWeb) {
        // On web, we need to fetch the blob URL and convert to base64
        final response = await http.get(Uri.parse(filePath));
        if (response.statusCode == 200) {
          base64String = base64Encode(response.bodyBytes);
        } else {
          throw Exception('Failed to read file on web');
        }
      } else {
        // On mobile/desktop, read file normally
        final bytes = await File(filePath).readAsBytes();
        base64String = base64Encode(bytes);
      }

      print(
        'File converted to base64, size: ${base64String.length} characters',
      );

      // Prepare the request body matching your backend expectations
      final requestBody = {
        'image': base64String, // Your backend expects 'image' field
        'caption': caption,
      };

      print('Making API call to posts endpoint...');

      // Make API request to your correct endpoint
      final response = await ApiClient.postJson(
        '${ApiConfig.api}/posts/',
        requestBody,
        auth: true,
      );

      print('=== POST CREATION RESPONSE ===');
      print('Status Code: ${response['statusCode']}');
      print('Response Body: $response');
      print('==============================');

      if ((response['statusCode'] ?? 0) == 201) {
        // Success - post created
        final responseData = response;
        final id = responseData['id'] ?? responseData['data']?['id'];
        final imageUrl =
            responseData['image_url'] ?? responseData['data']?['image_url'];
        print('Post created successfully with ID: $id');
        print('Image uploaded to Cloudinary: $imageUrl');
      } else if ((response['statusCode'] ?? 0) == 400) {
        // Bad request - parse error message
        final errorMessage =
            response['message'] ?? response['error'] ?? 'Bad request';
        throw Exception(errorMessage);
      } else if ((response['statusCode'] ?? 0) == 401) {
        // Unauthorized
        throw Exception('Authentication failed. Please login again.');
      } else if ((response['statusCode'] ?? 0) == 500) {
        // Server error
        final errorMessage =
            response['message'] ?? response['error'] ?? 'Server error';
        throw Exception(errorMessage);
      } else {
        // Other errors
        throw Exception(
          'Failed to create post (HTTP ${response['statusCode']})',
        );
      }
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: whiteColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(goldColor),
            ),
            SizedBox(height: 16),
            Text(message, style: TextStyle(color: blackColor, fontSize: 16)),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textStyle;
    final formFactor = context.formFactor;

    // Define responsive sizes based on device type
    double appBarHeight;
    double avatarRadius;
    double spacing;

    switch (formFactor) {
      case FormFactorType.mobile:
        appBarHeight = 56.0;
        avatarRadius = 16.0;
        spacing = 8.0;
        break;
      case FormFactorType.tablet:
        appBarHeight = 64.0;
        avatarRadius = 20.0;
        spacing = 12.0;
        break;
      case FormFactorType.desktop:
        appBarHeight = 72.0;
        avatarRadius = 24.0;
        spacing = 16.0;
        break;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: whiteColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: whiteColor,
            border: Border(
              bottom: BorderSide(color: greyColor.withOpacity(0.3)),
            ),
          ),
          child: AppBar(
            elevation: 0,
            backgroundColor: whiteColor,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Icon(Icons.menu, color: blackColor),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLoading ? 'Loading...' : userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: blackColor,
                  ),
                ),
                if (isVerified) ...[
                  SizedBox(width: 4),
                  Icon(Icons.verified, color: brightGold, size: 16),
                ],
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add_box_outlined, color: blackColor),
                onPressed: _handleNewStoryTap, // Fixed: Use the correct handler
              ),
              IconButton(
                icon: Icon(Icons.menu, color: blackColor),
                onPressed: () {
                  // Show options menu
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: whiteColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) => _buildOptionsMenu(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      drawer: _buildSidebar(),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(color: greyColor),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header Section
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Profile image, stats, and buttons row
                        Row(
                          children: [
                            // Profile Image
                            _getProfileImage(radius: 45),
                            SizedBox(width: 20),

                            // Stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn('120', 'Followers'),
                                _buildStatColumn('45', 'Posts'),
                                _buildStatColumn('30', 'Likes'),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Bio section
                        Container(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (userLocation.isNotEmpty)
                                Text(
                                  userLocation,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: blackColor,
                                  ),
                                ),
                              SizedBox(height: 4),
                              Text(
                                userBio,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: blackColor,
                                ),
                              ),
                              if (userEmail.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: greyColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Edit profile functionality
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Opening Edit Profile...',
                                        ),
                                        backgroundColor: goldColor,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: greyColor.withOpacity(0.2),
                                    foregroundColor: blackColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    'Edit profile',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: () => Get.to(
                                    () => CommentSection(),
                                    transition: Transition.upToDown,
                                    duration: const Duration(milliseconds: 500),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: goldColor,
                                    foregroundColor: blackColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    'View archive',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              height: 32,
                              width: 32,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Settings functionality
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SettingsScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: greyColor.withOpacity(0.2),
                                  foregroundColor: blackColor,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: Icon(
                                  Icons.person_add_outlined,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Story highlights with enhanced "New" button
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStoryHighlight(
                                isNew: true,
                                title: 'New',
                                onTap:
                                    _handleNewStoryTap, // Fixed: Use the correct handler
                              ),
                              // Add more story highlights here if needed
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab bar and posts grid
                  DefaultTabController(
                    length: 4,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(icon: Icon(Icons.grid_on)),
                            Tab(icon: Icon(Icons.play_arrow)),
                            Tab(icon: Icon(Icons.bookmark_border)),
                            Tab(icon: Icon(Icons.person_outline)),
                          ],
                          labelColor: blackColor,
                          unselectedLabelColor: greyColor,
                          indicatorColor: blackColor,
                          indicatorWeight: 1,
                        ),
                        Container(
                          height: 400, // Fixed height for the tab view
                          child: TabBarView(
                            children: [
                              // Posts tab
                              // In your TabBarView, update the Posts tab:
FutureBuilder<List<Map<String, dynamic>>>(
  future: _futureMyPosts,
  builder: (context, snapshot) {
    final posts = snapshot.data ?? [];
    return GridView.builder(
      padding: EdgeInsets.all(1),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1.0,
      ),
      itemCount: posts.isEmpty ? 6 : posts.length,
      itemBuilder: (context, index) {
        final post = posts.isEmpty 
            ? null 
            : posts[index];
        final imageUrl = post != null 
            ? post['image_url'] ?? "https://picsum.photos/200/300?random=$index"
            : "https://picsum.photos/200/300?random=$index";
            
        return GestureDetector(
          onTap: () {
            if (post != null) {
              // Navigate to PostDetailScreen with the full post data
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: post),
                ),
              ).then((_) {
                // Refresh posts when coming back from detail screen
                setState(() {
                  _futureMyPosts = _fetchMyPostsWithFullData();
                });
              });
            } else {
              // Handle placeholder posts - maybe show a message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('This is a placeholder post'),
                  backgroundColor: greyColor,
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: greyColor.withOpacity(0.1),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: greyColor.withOpacity(0.2),
                      child: Icon(
                        Icons.image,
                        color: greyColor,
                        size: 40,
                      ),
                    );
                  },
                ),
                // Add a subtle overlay to indicate it's tappable
                if (post != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: blackColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            color: whiteColor,
                            size: 12,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${post['likes_count'] ?? 0}',
                            style: TextStyle(
                              color: whiteColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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
    );
  },
),
                              
                              // Reels tab
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_circle_outline,
                                      size: 60,
                                      color: greyColor,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No reels yet',
                                      style: TextStyle(
                                        color: greyColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Saved tab
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bookmark_outline,
                                      size: 60,
                                      color: greyColor,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No saved posts',
                                      style: TextStyle(
                                        color: greyColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Tagged tab
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 60,
                                      color: greyColor,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No tagged posts',
                                      style: TextStyle(
                                        color: greyColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn(String number, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: blackColor,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: blackColor)),
      ],
    );
  }

  Widget _buildStoryHighlight({
    bool isNew = false,
    required String title,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isNew ? greyColor.withOpacity(0.3) : goldColor,
                  width: 2,
                ),
              ),
              child: isNew
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            goldColor.withOpacity(0.1),
                            goldColor.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(Icons.add, size: 30, color: goldColor),
                    )
                  : CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                        "https://picsum.photos/100/100",
                      ),
                    ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: blackColor,
                fontWeight: isNew ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsMenu() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.my_location, color: blackColor),
            title: Text('Set Coordinates'),
            onTap: () async {
              Navigator.pop(context);
              await _showSetCoordsDialog();
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: blackColor),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.description, color: blackColor),
            title: Text('Terms and Conditions'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TermsAndConditionsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showSetCoordsDialog() async {
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set Coordinates'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              TextField(
                controller: lonCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final id = await UserSession.getUserId();
                  if (id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Not logged in')),
                    );
                    return;
                  }
                  final lat = double.tryParse(latCtrl.text.trim());
                  final lon = double.tryParse(lonCtrl.text.trim());
                  if (lat == null || lon == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid coordinates')),
                    );
                    return;
                  }
                  final res = await ApiClient.postJson(
                    '${ApiConfig.api}/advertisers/$id/coords',
                    {'latitude': lat, 'longitude': lon},
                    auth: true,
                  );
                  if ((res['statusCode'] ?? 500) >= 200 &&
                      (res['statusCode'] ?? 500) < 300) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coordinates updated')),
                    );
                    setState(() {});
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed: ${res['message'] ?? res['error'] ?? ''}',
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update coordinates'),
                    ),
                  );
                } finally {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: whiteColor,
      child: Column(
        children: [
          // Enhanced header with gradient
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [goldColor, brightGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: blackColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getProfileImage(radius: 45),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLoading ? 'Loading...' : userName,
                      style: TextStyle(
                        color: blackColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isVerified) ...[
                      SizedBox(width: 8),
                      Icon(Icons.verified, color: blackColor, size: 20),
                    ],
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Advertiser",
                      style: TextStyle(
                        color: blackColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    if (isOnline) ...[
                      SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Enhanced menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(height: 10),
                _buildDrawerItem(
                  icon: Icons.edit,
                  title: "Edit Profile",
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening Edit Profile...'),
                        backgroundColor: goldColor,
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.subscriptions,
                  title: "Subscriptions",
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening Subscriptions...'),
                        backgroundColor: goldColor,
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: "Settings",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.description,
                  title: "Terms and Conditions",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TermsAndConditionsScreen(),
                      ),
                    );
                  },
                ),
                Divider(
                  color: greyColor.withOpacity(0.3),
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: "Logout",
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLogout
                ? Colors.red.withOpacity(0.1)
                : goldColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red : blackColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red : blackColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: goldColor.withOpacity(0.1),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 24),
              SizedBox(width: 10),
              Text(
                "Logout",
                style: TextStyle(
                  color: blackColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to logout from your account?",
            style: TextStyle(color: darkGreyColor, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: greyColor, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  // Clear user session
                  await UserSession.clearSession();

                  // Navigate back to login screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => Login()),
                    (route) => false,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.logout, color: whiteColor),
                          SizedBox(width: 12),
                          Text(
                            'Logged out successfully!',
                            style: TextStyle(
                              color: whiteColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: whiteColor,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Logout",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}