import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/screens/shared%20screens/reviewspage.dart';
import 'package:escort/styles/app_size.dart';
import 'package:escort/styles/post_cards_styling.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdvertiserProfile extends StatefulWidget {
  const AdvertiserProfile({super.key});

  @override
  State<AdvertiserProfile> createState() => _AdvertiserProfileState();
}

class _AdvertiserProfileState extends State<AdvertiserProfile> {
  @override
  Widget build(BuildContext context) {
    final textStyle = context.textStyle;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight * 1.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: AppBar(
            elevation: 0,
            backgroundColor: colorScheme.surface,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {},
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage("assets/images/profile.png"),
                  radius: avatarRadius,
                ),

                SizedBox(width: spacing),
                Text(
                  "username",
                  style: TextStyle(
                    fontWeight: textStyle.titleSmBold.fontWeight,
                    fontSize: textStyle.titleSmBold.fontSize,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              SizedBox(width: spacing),
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {},
              ),
              SizedBox(width: spacing),
              IconButton(
                icon: const Icon(Icons.message_rounded),
                onPressed: () {},
              ),
            ],
            automaticallyImplyLeading: false,
            titleSpacing: 0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              SizedBox(height: Sizes.spaceBtwSections),
              // Circular avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: formFactor == FormFactorType.desktop
                        ? avatarRadius * 2.5
                        : formFactor == FormFactorType.tablet
                        ? avatarRadius * 2
                        : avatarRadius * 1.5,
                    backgroundImage: AssetImage("assets/images/profile.png"),
                  ),
                  //the online status indicator
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Sizes.spaceBtwItems),
              // Description section
              Text(
                "Description",
                style: TextStyle(
                  fontWeight: textStyle.bodyMdMedium.fontWeight,
                  fontSize: textStyle.bodyMdMedium.fontSize,
                  color: Colors.black,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: Sizes.spaceBtwItems),
                  // Message button takes the user to the message page
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(
                          Sizes.buttonRadius + 5,
                        ),
                      ),
                    ),

                    ///redirect to message page
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Messages"),
                        SizedBox(width: 8),
                        Icon(Icons.chat_bubble_outline_rounded),
                      ],
                    ),
                  ),
                ],
              ),
              // Reviews button when clicked slides up to the reviews page
              // advertiser will see she/ he was left by the reviewer
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Sizes.defaultSpace),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // Posts grid scrollable and adjusted to the screen size
                  children: [
                    ElevatedButton(
                      onPressed: () => Get.to(
                        () => CommentSection(),
                        transition: Transition.upToDown,
                        duration: const Duration(milliseconds: 500),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: Text(
                        "See Reviews",
                        style: TextStyle(
                          fontWeight: textStyle.titleSmBold.fontWeight,
                          fontSize: textStyle.titleSmBold.fontSize,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      //from the gallery or camera
                      child: Text(
                        "Add Post",
                        style: TextStyle(
                          fontWeight: textStyle.titleSmBold.fontWeight,
                          fontSize: textStyle.titleSmBold.fontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Sizes.spaceBtwItems),
              // Posts grid scrollable and adjusted to the screen size
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
                itemCount:
                    20, // Number of posts can be dynamic gotten from the backend
                itemBuilder: (context, index) {
                  return PostCard(
                    imageUrl: "https://picsum.photos/200/300?random=$index",
                  ); // to be picked for the gallery or camera for the real post
                },
              ),
              SizedBox(height: Sizes.spaceBtwItems * 2.5),
            ],
          ),
        ),
      ),
    );
  }
}
