import 'package:flutter/material.dart';
import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/styles/app_size.dart';
import 'package:escort/styles/post_cards_styling.dart';
import 'package:get/get.dart';
import 'package:escort/screens/shared_screens/reviewspage.dart';

class PostsSection extends StatelessWidget {
  final int postCount;
  final VoidCallback onSeeReviewsPressed;

  const PostsSection({
    super.key,
    required this.postCount,
    required this.onSeeReviewsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final formFactor = context.formFactor;
    final colorScheme = Theme.of(context).colorScheme;

    int crossAxisCount;
    switch (formFactor) {
      case FormFactorType.mobile:
        crossAxisCount = 2;
        break;
      case FormFactorType.tablet:
        crossAxisCount = 3;
        break;
      case FormFactorType.desktop:
        crossAxisCount = 4;
        break;
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Sizes.defaultSpace),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Posts $postCount",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Colors.black,
                ),
              ),
              ElevatedButton(
                onPressed: () => Get.to(
                  () => const CommentSection(),
                  transition: Transition.upToDown,
                  duration: const Duration(milliseconds: 500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text("See Reviews"),
              ),
            ],
          ),
        ),
        SizedBox(height: Sizes.spaceBtwItems),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: Sizes.defaultSpace),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: Sizes.spaceBtwItems,
            mainAxisSpacing: Sizes.spaceBtwItems,
            childAspectRatio: 1.0,
          ),
          itemCount: postCount,
          itemBuilder: (context, index) {
            return PostCard(
              imageUrl: "https://picsum.photos/200/300?random=$index",
            );
          },
        ),
      ],
    );
  }
}
