import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/screens/settings_screen.dart';
import 'package:escort/screens/shared_screens/reviewspage.dart';
import 'package:escort/screens/terms_and_conditions_screen.dart';
import 'package:escort/styles/app_size.dart';
import 'package:escort/styles/post_cards_styling.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  static const Color brightGold = Color(0xFFFFC107); // Brighter gold variant
  static const Color blackColor = Color(0xFF000000);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color greyColor = Color(0xFF808080);
  static const Color darkGreyColor = Color(0xFF404040);

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
        preferredSize: Size.fromHeight(appBarHeight * 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: whiteColor,
            border: Border(bottom: BorderSide(color: greyColor.withOpacity(0.3))),
            boxShadow: [
              BoxShadow(
                color: blackColor.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            elevation: 0,
            backgroundColor: whiteColor,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: blackColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: goldColor, width: 2),
                    ),
                    child: CircleAvatar(
                      backgroundImage: AssetImage("https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&h=100&fit=crop&crop=face"),
                      radius: avatarRadius,
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Text(
                  "Kriston",
                  style: TextStyle(
                    fontWeight: textStyle.titleSmBold.fontWeight,
                    fontSize: textStyle.titleSmBold.fontSize,
                    color: blackColor,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: blackColor),
                onPressed: () {},
              ),
              SizedBox(width: spacing),
              IconButton(
                icon: const Icon(Icons.notifications, color: blackColor),
                onPressed: () {},
              ),
              SizedBox(width: spacing),
              IconButton(
                icon: const Icon(Icons.message_rounded, color: blackColor),
                onPressed: () {},
              ),
            ],
            automaticallyImplyLeading: false,
            titleSpacing: 0,
          ),
        ),
      ),
      drawer: _buildSidebar(),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              SizedBox(height: Sizes.spaceBtwSections),
              // Enhanced circular avatar with gold border
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: goldColor, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: formFactor == FormFactorType.desktop
                          ? avatarRadius * 2.5
                          : formFactor == FormFactorType.tablet
                          ? avatarRadius * 2
                          : avatarRadius * 1.5,
                      backgroundImage: AssetImage("https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&h=100&fit=crop&crop=face"),
                    ),
                  ),
                  // Enhanced online status indicator
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: brightGold,
                        shape: BoxShape.circle,
                        border: Border.all(color: whiteColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: blackColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Sizes.spaceBtwItems),
              // Enhanced description section
              Container(
                padding: EdgeInsets.symmetric(horizontal: Sizes.defaultSpace),
                child: Text(
                  "Professional escort services with premium quality and discretion",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: textStyle.bodyMdMedium.fontWeight,
                    fontSize: textStyle.bodyMdMedium.fontSize,
                    color: darkGreyColor,
                  ),
                ),
              ),
              SizedBox(height: Sizes.spaceBtwItems),
              // Enhanced message button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Sizes.buttonRadius + 5),
                  boxShadow: [
                    BoxShadow(
                      color: goldColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to messages page
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening messages...'),
                        backgroundColor: goldColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: blackColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Sizes.buttonRadius + 5,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Messages",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.chat_bubble_outline_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Sizes.spaceBtwItems),
              // Enhanced action buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Sizes.defaultSpace),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                          boxShadow: [
                            BoxShadow(
                              color: blackColor.withOpacity(0.2),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Get.to(
                            () => CommentSection(),
                            transition: Transition.upToDown,
                            duration: const Duration(milliseconds: 500),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blackColor,
                            foregroundColor: goldColor,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "See Reviews",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                          boxShadow: [
                            BoxShadow(
                              color: goldColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _showAddPostDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            foregroundColor: blackColor,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Add Post",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Sizes.spaceBtwItems * 1.5),
              // Enhanced posts grid
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: Sizes.defaultSpace),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: formFactor == FormFactorType.desktop
                      ? 4
                      : formFactor == FormFactorType.tablet
                      ? 3
                      : 2,
                  crossAxisSpacing: Sizes.spaceBtwItems,
                  mainAxisSpacing: Sizes.spaceBtwItems,
                  childAspectRatio: 1.0,
                ),
                itemCount: 20,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: blackColor.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: PostCard(
                      imageUrl: "https://picsum.photos/200/300?random=$index",
                    ),
                  );
                },
              ),
              SizedBox(height: Sizes.spaceBtwItems * 2.5),
            ],
          ),
        ),
      ),
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
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: whiteColor, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundImage: AssetImage("https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&h=100&fit=crop&crop=face"),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  "Kriston",
                  style: TextStyle(
                    color: blackColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Advertiser",
                  style: TextStyle(
                    color: blackColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
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
                    // Navigate to edit profile page
                    // Get.to(() => EditProfilePage());
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
                    // Navigate to subscriptions page
                    // Get.to(() => SubscriptionsPage());
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
                      MaterialPageRoute(builder: (context) => TermsAndConditionsScreen()),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hoverColor: goldColor.withOpacity(0.1),
      ),
    );
  }

  void _showAddPostDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Add New Post",
            style: TextStyle(
              color: blackColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose media source:",
                style: TextStyle(
                  color: darkGreyColor,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaOption(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    onTap: () {
                      Navigator.pop(context);
                      _pickMedia(ImageSource.camera);
                    },
                  ),
                  _buildMediaOption(
                    icon: Icons.photo_library,
                    label: "Gallery",
                    onTap: () {
                      Navigator.pop(context);
                      _pickMedia(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: goldColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: goldColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: goldColor.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: blackColor),
            SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: blackColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Select Media Type",
            style: TextStyle(
              color: blackColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMediaTypeOption(
                icon: Icons.image,
                title: "Photo",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(source);
                },
              ),
              SizedBox(height: 10),
              _buildMediaTypeOption(
                icon: Icons.videocam,
                title: "Video",
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(source);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaTypeOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: goldColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: goldColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: blackColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      hoverColor: goldColor.withOpacity(0.1),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        _showPostDetailsDialog(image.path, isVideo: false);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: Duration(minutes: 10),
      );
      if (video != null) {
        _showPostDetailsDialog(video.path, isVideo: true);
      }
    } catch (e) {
      print('Error picking video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking video. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPostDetailsDialog(String filePath, {required bool isVideo}) {
    final TextEditingController captionController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

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
              Icon(
                isVideo ? Icons.videocam : Icons.image,
                color: goldColor,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                "Post Details",
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
                // Enhanced media preview
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
                                  "Video Preview",
                                  style: TextStyle(
                                    color: darkGreyColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Image.file(
                            File(filePath),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                SizedBox(height: 25),
                // Enhanced caption input
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
                  decoration: InputDecoration(
                    hintText: "Write a caption for your post...",
                    hintStyle: TextStyle(color: greyColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: greyColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: goldColor, width: 2),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(color: blackColor),
                ),
                SizedBox(height: 20),
                // Enhanced price input
                Text(
                  "Price",
                  style: TextStyle(
                    color: blackColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: "0.00",
                    hintStyle: TextStyle(color: greyColor),
                    prefixText: "\$ ",
                    prefixStyle: TextStyle(
                      color: goldColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: greyColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: goldColor, width: 2),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(color: blackColor),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                onPressed: () {
                  if (captionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please add a caption'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (priceController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please add a price'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  _createPost(
                    filePath: filePath,
                    caption: captionController.text,
                    price: priceController.text,
                    isVideo: isVideo,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  foregroundColor: blackColor,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  }

  void _createPost({
    required String filePath,
    required String caption,
    required String price,
    required bool isVideo,
  }) {
    // Implement post creation logic here
    // This would typically involve uploading the media to your backend
    // and saving the post data
    print('Creating post:');
    print('File: $filePath');
    print('Caption: $caption');
    print('Price: \${price}');
    print('Is Video: $isVideo');
    
    // Show enhanced success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: blackColor),
            SizedBox(width: 12),
            Text(
              'Post created successfully!',
              style: TextStyle(
                color: blackColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: goldColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: 3),
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
              Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
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
            style: TextStyle(
              color: darkGreyColor,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Implement logout logic
                  // Get.offAll(() => LoginPage());
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
  }
}