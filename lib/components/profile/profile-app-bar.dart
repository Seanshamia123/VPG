import 'package:flutter/material.dart';
import 'package:escort/device_utility/device_checker.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String username;
  final String avatarImage;
  final VoidCallback onBackPressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onMessagesPressed;
  final double height;

  const ProfileAppBar({
    Key? key,
    required this.username,
    required this.avatarImage,
    required this.onBackPressed,
    required this.onSearchPressed,
    required this.onNotificationsPressed,
    required this.onMessagesPressed,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formFactor = context.formFactor;
    final colorScheme = Theme.of(context).colorScheme;

    double avatarRadius;
    double spacing;
    switch (formFactor) {
      case FormFactorType.mobile:
        avatarRadius = 16.0;
        spacing = 8.0;
        break;
      case FormFactorType.tablet:
        avatarRadius = 20.0;
        spacing = 12.0;
        break;
      case FormFactorType.desktop:
        avatarRadius = 24.0;
        spacing = 16.0;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed,
        ),
        title: Row(
          children: [
            (avatarImage.isNotEmpty)
                ? CircleAvatar(
                    backgroundImage: avatarImage.startsWith('http')
                        ? NetworkImage(avatarImage)
                        : AssetImage(avatarImage) as ImageProvider,
                    radius: avatarRadius,
                  )
                : CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.grey.shade300,
                    child: Icon(Icons.person, color: Colors.grey.shade700, size: avatarRadius),
                  ),
            SizedBox(width: spacing),
            Text(
              username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearchPressed,
          ),
          SizedBox(width: spacing),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: onNotificationsPressed,
          ),
          SizedBox(width: spacing),
          IconButton(
            icon: const Icon(Icons.message_rounded),
            onPressed: onMessagesPressed,
          ),
        ],
        automaticallyImplyLeading: false,
        titleSpacing: 0,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
/// Component: Profile App Bar
