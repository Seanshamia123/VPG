import 'package:escort/widgets/profile/post-section.dart';
import 'package:escort/widgets/profile/profile-action-buttons.dart';
import 'package:escort/widgets/profile/profile-app-bar.dart';
import 'package:escort/widgets/profile/profile-header.dart';
import 'package:flutter/material.dart';
import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/styles/app_size.dart';

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
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

    return Scaffold(
      appBar: ProfileAppBar(
        username: "username",
        avatarImage: "assets/images/profile.png",
        onBackPressed: () {},
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
                avatarImage: "assets/images/profile.png",
                description: "Description",
              ),
              ProfileActionButtons(
                onPayPressed: () {},
                onMessagePressed: () {},
              ),
              PostsSection(postCount: 20, onSeeReviewsPressed: () {}),
              SizedBox(height: Sizes.spaceBtwItems * 2),
            ],
          ),
        ),
      ),
    );
  }
}
