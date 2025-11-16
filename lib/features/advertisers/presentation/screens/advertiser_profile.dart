/// Feature: Advertisers
/// Screen: AdvertiserProfile (self profile for advertisers)
import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/features/advertisers/presentation/screens/subscription_plans_page.dart';
import 'package:escort/features/settings/presentation/screens/settings_screen.dart';
import 'package:escort/features/advertisers/presentation/screens/reviewspage.dart';
import 'package:escort/features/advertisers/presentation/screens/subscription_status_widget.dart';
import 'package:escort/features/settings/presentation/screens/terms_and_conditions_screen.dart';
import 'package:escort/services/advertiser_service.dart';
import 'package:escort/services/user_session.dart';
import 'package:escort/features/auth/presentation/screens/login.dart';
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
import 'package:escort/features/advertisers/presentation/screens/advertiser_edit_profile.dart';

class AdvertiserProfile extends StatefulWidget {
  const AdvertiserProfile({super.key});

  @override
  State<AdvertiserProfile> createState() => _AdvertiserProfileState();
}

class _AdvertiserProfileState extends State<AdvertiserProfile> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _picker = ImagePicker();

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

  // Updated color getters to match home_screen.dart
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  ThemeData get _theme => Theme.of(context);
  TextTheme get _textTheme => Theme.of(context).textTheme;
  bool get _isDark => _theme.brightness == Brightness.dark;

  Color get _primaryColor => _scheme.primary;
  Color get _onPrimaryColor => _scheme.onPrimary;
  Color get _surfaceColor => _theme.scaffoldBackgroundColor;
  Color get _surfaceVariantColor => _scheme.surface;
  Color get _onSurfaceColor => _scheme.onSurface;
  Color get _onSurfaceVariantColor => _scheme.onSurfaceVariant;
  Color get _dividerColor => _theme.dividerColor;

  Color get _panelBackgroundColor =>
      _isDark ? const Color(0xFF111315) : _surfaceColor;
  Color get _panelSurfaceColor =>
      _isDark ? const Color(0xFF1F2426) : _surfaceVariantColor;
  Color get _panelCardColor =>
      _isDark ? const Color(0xFF1C1F20) : _theme.cardColor;
  Color get _textPrimaryColor =>
      _isDark ? Colors.white : _onSurfaceColor;
  Color get _textSecondaryColor =>
      _isDark ? Colors.white70 : _onSurfaceVariantColor;
  Color get _borderNeutralColor =>
      _isDark ? Colors.white24 : _dividerColor;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  late Future<List<Map<String, dynamic>>> _futureMyPosts =
      _fetchMyPostsWithFullData();

  Future<List<Map<String, dynamic>>> _fetchPostsByAdvertiserId(
    int advertiserId,
  ) async {
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

  Future<List<Map<String, dynamic>>> _fetchMyPostsFullData() async {
    try {
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

  Future<List<Map<String, dynamic>>> _fetchMyPostsWithFullData() async {
    try {
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

  Future<void> _loadUserData() async {
    try {
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

  Widget _getProfileImage({required double radius, bool showBorder = true}) {
    Widget imageWidget;

    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      imageWidget = CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(profileImageUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          print('Error loading profile image: $exception');
        },
      );
    } else {
      imageWidget = CircleAvatar(
        radius: radius,
        backgroundColor: _panelSurfaceColor,
        child: Icon(Icons.person, color: _textSecondaryColor, size: radius),
      );
    }

    if (showBorder) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isVerified ? _primaryColor : _borderNeutralColor,
            width: isVerified ? 3 : 2,
          ),
        ),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

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
        color: _panelSurfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.1),
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
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: _textSecondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.add_circle, color: _primaryColor, size: 28),
                SizedBox(width: 12),
                Text(
                  'Create New Post',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textPrimaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Choose how you want to add media',
              style: TextStyle(color: _textSecondaryColor, fontSize: 16),
            ),
            SizedBox(height: 30),
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
          color: _primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryColor.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.1),
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
                color: _primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: _textPrimaryColor),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimaryColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: _textSecondaryColor),
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
      backgroundColor: _panelSurfaceColor,
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
                color: _textPrimaryColor,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: _primaryColor),
              ),
              title: Text('Take Photo', style: TextStyle(color: _textPrimaryColor)),
              subtitle: Text('Capture a new photo', style: TextStyle(color: _textSecondaryColor)),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessMedia(ImageSource.camera, isVideo: false);
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.videocam, color: _primaryColor),
              ),
              title: Text('Record Video', style: TextStyle(color: _textPrimaryColor)),
              subtitle: Text('Record a new video', style: TextStyle(color: _textSecondaryColor)),
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
      backgroundColor: _panelSurfaceColor,
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
                color: _textPrimaryColor,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image, color: _primaryColor),
              ),
              title: Text('Select Photo', style: TextStyle(color: _textPrimaryColor)),
              subtitle: Text('Choose photo from gallery', style: TextStyle(color: _textSecondaryColor)),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessMedia(ImageSource.gallery, isVideo: false);
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.video_library, color: _primaryColor),
              ),
              title: Text('Select Video', style: TextStyle(color: _textPrimaryColor)),
              subtitle: Text('Choose video from gallery', style: TextStyle(color: _textSecondaryColor)),
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
          imageQuality: 80,
          maxWidth: 1280,
          maxHeight: 1280,
        );
      }

      Navigator.pop(context);

      if (pickedFile != null) {
        String mediaPath;

        if (kIsWeb) {
          mediaPath = pickedFile.path;
        } else {
          mediaPath = pickedFile.path;
        }

        if (isVideo) {
          await _showPostCreationDialog(mediaPath, isVideo: true);
        } else {
          await _showImageEditingOptions(mediaPath);
        }
      }
    } catch (e) {
      Navigator.pop(context);
      print('Error picking media: $e');
      _showErrorSnackBar('Error selecting media. Please try again.');
    }
  }

  Future<void> _showImageEditingOptions(String imagePath) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: _panelSurfaceColor,
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
                color: _textPrimaryColor,
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _primaryColor, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: kIsWeb
                    ? Image.network(imagePath, fit: BoxFit.cover)
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
          color: _primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _primaryColor, size: 28),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: _textPrimaryColor, fontWeight: FontWeight.w600),
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
            toolbarColor: _primaryColor,
            toolbarWidgetColor: _textPrimaryColor,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            statusBarColor: _primaryColor,
            backgroundColor: _panelBackgroundColor,
            activeControlsWidgetColor: _primaryColor,
            dimmedLayerColor: _textPrimaryColor.withOpacity(0.8),
            cropFrameColor: _primaryColor,
            cropGridColor: _primaryColor.withOpacity(0.5),
          ),
          IOSUiSettings(
            title: 'Crop Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
          ),
        ],
      );

      Navigator.pop(context);

      if (croppedFile != null) {
        await _showPostCreationDialog(croppedFile.path, isVideo: false);
      }
    } catch (e) {
      Navigator.pop(context);
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
              backgroundColor: _panelSurfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    isVideo ? Icons.videocam : Icons.image,
                    color: _primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Create Post",
                    style: TextStyle(
                      color: _textPrimaryColor,
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
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _primaryColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _textPrimaryColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: isVideo
                            ? Container(
                                color: _textPrimaryColor.withOpacity(0.1),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_circle_filled,
                                      size: 60,
                                      color: _primaryColor,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Video Ready",
                                      style: TextStyle(
                                        color: _textSecondaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : kIsWeb
                            ? Image.network(filePath, fit: BoxFit.cover)
                            : Image.file(File(filePath), fit: BoxFit.cover),
                      ),
                    ),
                    SizedBox(height: 25),
                    Text(
                      "Caption",
                      style: TextStyle(
                        color: _textPrimaryColor,
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
                        hintStyle: TextStyle(color: _textSecondaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _textSecondaryColor.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _primaryColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      style: TextStyle(color: _textPrimaryColor),
                    ),
                    if (isPosting) ...[
                      SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _primaryColor,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Creating your post...',
                              style: TextStyle(color: _textSecondaryColor, fontSize: 14),
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
                            color: _textSecondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.3),
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
                            backgroundColor: _primaryColor,
                            foregroundColor: _textPrimaryColor,
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

      final accessToken = await UserSession.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      String base64String;

      if (kIsWeb) {
        final response = await http.get(Uri.parse(filePath));
        if (response.statusCode == 200) {
          base64String = base64Encode(response.bodyBytes);
        } else {
          throw Exception('Failed to read file on web');
        }
      } else {
        final bytes = await File(filePath).readAsBytes();
        base64String = base64Encode(bytes);
      }

      print(
        'File converted to base64, size: ${base64String.length} characters',
      );

      final requestBody = {
        'image': base64String,
        'caption': caption,
      };

      print('Making API call to posts endpoint...');

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
        final responseData = response;
        final id = responseData['id'] ?? responseData['data']?['id'];
        final imageUrl =
            responseData['image_url'] ?? responseData['data']?['image_url'];
        print('Post created successfully with ID: $id');
        print('Image uploaded to Cloudinary: $imageUrl');
      } else if ((response['statusCode'] ?? 0) == 400) {
        final errorMessage =
            response['message'] ?? response['error'] ?? 'Bad request';
        throw Exception(errorMessage);
      } else if ((response['statusCode'] ?? 0) == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if ((response['statusCode'] ?? 0) == 500) {
        final errorMessage =
            response['message'] ?? response['error'] ?? 'Server error';
        throw Exception(errorMessage);
      } else {
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
        backgroundColor: _panelSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
            SizedBox(height: 16),
            Text(message, style: TextStyle(color: _textPrimaryColor, fontSize: 16)),
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
            Icon(Icons.check_circle, color: _onPrimaryColor),
            SizedBox(width: 12),
            Text(
              message,
              style: TextStyle(color: _onPrimaryColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: _primaryColor,
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
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
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

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _panelBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: _panelSurfaceColor,
            border: Border(
              bottom: BorderSide(
                color: _borderNeutralColor.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Icon(Icons.menu, color: _textPrimaryColor),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLoading ? 'Loading...' : userName,
                  style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _textPrimaryColor,
                      ) ??
                      TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: _textPrimaryColor,
                      ),
                ),
                if (isVerified) ...[
                  SizedBox(width: 4),
                  Icon(Icons.verified, color: _primaryColor, size: 16),
                ],
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.message_outlined, color: _textPrimaryColor),
                tooltip: 'Messages',
                onPressed: () {
                  Navigator.of(context).pushNamed('/messages');
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
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: textTheme.bodyMedium?.copyWith(
                          color: _textSecondaryColor,
                        ) ??
                        TextStyle(color: _textSecondaryColor),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header Section - UPDATED (removed stats and buttons)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Centered profile section
                        Column(
                          children: [
                            // Profile Image - centered
                            _getProfileImage(radius: 45),
                            SizedBox(height: 16),
                          ],
                        ),

                        // Bio section
                        Container(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (userLocation.isNotEmpty)
                                Text(
                                  userLocation,
                                  style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimaryColor,
                                      ) ??
                                      TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _textPrimaryColor,
                                      ),
                                ),
                              SizedBox(height: 4),
                              Text(
                                userBio,
                                style: textTheme.bodyMedium?.copyWith(
                                      color: _textSecondaryColor,
                                    ) ??
                                    TextStyle(
                                      fontSize: 14,
                                      color: _textSecondaryColor,
                                    ),
                              ),
                              if (userEmail.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text(
                                  userEmail,
                                  style: textTheme.bodySmall?.copyWith(
                                        color: _textSecondaryColor,
                                      ) ??
                                      TextStyle(
                                        fontSize: 14,
                                        color: _textSecondaryColor,
                                      ),
                                ),
                              ],
                            ],
                          ),
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
                                onTap: _handleNewStoryTap,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        const SubscriptionStatusWidget(),
                        SizedBox(height: 20),
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
                          labelColor: _textPrimaryColor,
                          unselectedLabelColor: _textSecondaryColor,
                          indicatorColor: _primaryColor,
                          indicatorWeight: 2,
                        ),
                        Container(
                          height: 400,
                          child: TabBarView(
                            children: [
                              // Posts tab
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: _futureMyPosts,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _primaryColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          'Failed to load posts',
                                          style: TextStyle(color: _textSecondaryColor),
                                        ),
                                      ),
                                    );
                                  }
                                  final posts = snapshot.data ?? [];
                                  return GridView.builder(
                                    padding: EdgeInsets.all(1),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 1,
                                          mainAxisSpacing: 1,
                                          childAspectRatio: 1.0,
                                        ),
                                    itemCount: posts.length,
                                    itemBuilder: (context, index) {
                                      final post = posts[index];
                                      final imageUrl = (post['image_url'] ?? '')
                                          .toString();

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PostDetailScreen(post: post),
                                            ),
                                          ).then((_) {
                                            setState(() {
                                              _futureMyPosts =
                                                  _fetchMyPostsWithFullData();
                                            });
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _textSecondaryColor.withOpacity(0.1),
                                          ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              if (imageUrl.isNotEmpty)
                                                Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          color: _textSecondaryColor
                                                              .withOpacity(0.2),
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            color: _textSecondaryColor,
                                                            size: 40,
                                                          ),
                                                        );
                                                      },
                                                )
                                              else
                                                Container(
                                                  color: _textSecondaryColor.withOpacity(
                                                    0.2,
                                                  ),
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    color: _textSecondaryColor,
                                                    size: 40,
                                                  ),
                                                ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: Container(
                                                  padding: EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: _textPrimaryColor
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.favorite,
                                                        color: _surfaceColor,
                                                        size: 12,
                                                      ),
                                                      SizedBox(width: 2),
                                                      Text(
                                                        '${post['likes_count'] ?? 0}',
                                                        style: TextStyle(
                                                          color: _surfaceColor,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                      color: _textSecondaryColor,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No reels yet',
                                      style: TextStyle(
                                        color: _textSecondaryColor,
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
                                      color: _textSecondaryColor,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No saved posts',
                                      style: TextStyle(
                                        color: _textSecondaryColor,
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
                                      color: _textSecondaryColor,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No tagged posts',
                                      style: TextStyle(
                                        color: _textSecondaryColor,
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
                  color: isNew
                      ? _borderNeutralColor.withValues(alpha: 0.3)
                      : _primaryColor,
                  width: 2,
                ),
              ),
              child: isNew
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _primaryColor.withOpacity(0.1),
                            _primaryColor.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(Icons.add, size: 30, color: _primaryColor),
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
                color: _textPrimaryColor,
                fontWeight: isNew ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
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
          backgroundColor: _panelSurfaceColor,
          title: Text('Set Coordinates', style: TextStyle(color: _textPrimaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latCtrl,
                style: TextStyle(color: _textPrimaryColor),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  labelStyle: TextStyle(color: _textSecondaryColor),
                ),
              ),
              TextField(
                controller: lonCtrl,
                style: TextStyle(color: _textPrimaryColor),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  labelStyle: TextStyle(color: _textSecondaryColor),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: _textSecondaryColor)),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: _onPrimaryColor,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSetLocationDialog() async {
    final cityCtrl = TextEditingController();
    final countryCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _panelSurfaceColor,
          title: Text('Set Location', style: TextStyle(color: _textPrimaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cityCtrl,
                style: TextStyle(color: _textPrimaryColor),
                decoration: InputDecoration(
                  labelText: 'City',
                  labelStyle: TextStyle(color: _textSecondaryColor),
                ),
              ),
              TextField(
                controller: countryCtrl,
                style: TextStyle(color: _textPrimaryColor),
                decoration: InputDecoration(
                  labelText: 'Country',
                  labelStyle: TextStyle(color: _textSecondaryColor),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: _textSecondaryColor)),
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
                  final city = cityCtrl.text.trim();
                  final country = countryCtrl.text.trim();
                  if (city.isEmpty && country.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter city or country')),
                    );
                    return;
                  }
                  final location = [city, country]
                      .where((s) => s.isNotEmpty)
                      .join(city.isNotEmpty && country.isNotEmpty ? ', ' : '');
                  await AdvertiserService.updateProfile(
                    int.parse(id.toString()),
                    location: location,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location updated')),
                    );
                  }
                  Navigator.pop(ctx);
                  setState(() {});
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: _onPrimaryColor,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: _panelBackgroundColor,
      child: Column(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _panelSurfaceColor,
              boxShadow: [
                BoxShadow(
                  color: _textPrimaryColor.withOpacity(0.1),
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
                        color: _textPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isVerified) ...[
                      SizedBox(width: 8),
                      Icon(Icons.verified, color: _primaryColor, size: 20),
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
                        color: _textSecondaryColor,
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(height: 10),
                _buildDrawerItem(
                  icon: Icons.edit,
                  title: "Edit Profile",
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdvertiserEditProfileScreen(),
                      ),
                    );
                    if (result != null && mounted) {
                      await _loadUserData();
                      setState(() {});
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.subscriptions,
                  title: "Subscriptions",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionPlansPage(),
                      ),
                    ).then((result) {
                      if (result == true) {
                        _showSuccessSnackBar('Subscription activated successfully!');
                        setState(() {});
                      }
                    });
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
                  color: _textSecondaryColor.withOpacity(0.3),
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
                ? Colors.red.withValues(alpha: 0.1)
                : _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red : _textPrimaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red : _textPrimaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: _primaryColor.withOpacity(0.1),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _panelSurfaceColor,
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
                  color: _textPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to logout from your account?",
            style: TextStyle(color: _textSecondaryColor, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: _textSecondaryColor, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  await UserSession.clearSession();

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => Login()),
                    (route) => false,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Logged out successfully!',
                            style: TextStyle(
                              color: Colors.white,
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
                  foregroundColor: Colors.white,
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