import 'package:escort/widgets/profile/post-section.dart';
import 'package:escort/widgets/profile/profile-action-buttons.dart';
import 'package:escort/widgets/profile/profile-app-bar.dart';
import 'package:escort/widgets/profile/profile-header.dart';
import 'package:flutter/material.dart';
import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/styles/app_size.dart';
import 'package:escort/services/user_session.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:escort/services/user_service.dart';

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await UserSession.getCurrentUserData();
    setState(() {
      _user = data;
      _loading = false;
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final base64Str = base64Encode(bytes);
      final id = await UserSession.getUserId();
      if (id == null) return;
      final res = await UserService.uploadAvatar(int.parse(id.toString()), base64Str);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
        // Refresh local session
        final current = await UserSession.getCurrentUserData() ?? {};
        final updated = {...current, 'profile_image_url': res['profile_image_url']};
        await UserSession.saveUserSession(
          userData: updated,
          accessToken: (await UserSession.getAccessToken()) ?? '',
          refreshToken: null,
          userType: (await UserSession.getUserType()) ?? 'user',
        );
        setState(() => _user = updated);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update picture')));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final formFactor = context.formFactor;

    double appBarHeight;
    switch (formFactor) {
      case FormFactorType.mobile:
        appBarHeight = 56.0;
        break;
      case FormFactorType.tablet:
        appBarHeight = 64.0;
        break;
      case FormFactorType.desktop:
        appBarHeight = 72.0;
        break;
    }

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final name = _user?['name'] ?? _user?['username'] ?? 'User';
    final avatarUrl = _user?['profile_image_url']?.toString();
    return Scaffold(
      appBar: ProfileAppBar(
        username: name.toString(),
        avatarImage: avatarUrl ?? '',
        onBackPressed: () => Navigator.pop(context),
        onSearchPressed: () {},
        onNotificationsPressed: () {},
        onMessagesPressed: () {},
        height: appBarHeight,
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              ProfileHeader(
                avatarImage: avatarUrl ?? '',
                description: _user?['bio']?.toString() ?? '',
              ),
              ProfileActionButtons(
                onPayPressed: () {},
                onMessagePressed: () {},
              ),
              ElevatedButton(
                onPressed: _pickAndUploadAvatar,
                child: const Text('Upload Profile Picture'),
              ),
              PostsSection(postCount: 0, onSeeReviewsPressed: () {}),
              SizedBox(height: Sizes.spaceBtwItems * 2),
            ],
          ),
        ),
      ),
    );
  }
}
