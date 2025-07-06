import 'package:flutter/material.dart';
import 'package:escort/device_utility/device_checker.dart';
import 'package:escort/styles/app_size.dart';

class ProfileHeader extends StatelessWidget {
  final String avatarImage;
  final String description;

  const ProfileHeader({
    super.key,
    required this.avatarImage,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final formFactor = context.formFactor;

    double avatarRadius;
    switch (formFactor) {
      case FormFactorType.mobile:
        avatarRadius = 24.0; // 16.0 * 1.5
        break;
      case FormFactorType.tablet:
        avatarRadius = 40.0; // 20.0 * 2
        break;
      case FormFactorType.desktop:
        avatarRadius = 60.0; // 24.0 * 2.5
        break;
    }

    return Column(
      children: [
        SizedBox(height: Sizes.spaceBtwSections),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundImage: AssetImage(avatarImage),
            ),
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
        Text(
          description,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
