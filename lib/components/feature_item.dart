/// Shared Component: FeatureItem
///
/// Reusable row for highlighting a feature/capability with an icon.
import 'package:escort/constants/app_colors.dart';
import 'package:flutter/material.dart';

class FeatureItem extends StatelessWidget {
  final String text;
  final bool hasHoverEffect;
  final IconData icon;

  const FeatureItem({
    super.key,
    required this.text,
    this.hasHoverEffect = false,
    this.icon = Icons.check_circle,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: hasHoverEffect ? SystemMouseCursors.click : MouseCursor.defer,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 200),
        tween: Tween<double>(begin: 0, end: hasHoverEffect ? 1 : 0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(value * 4, 0),
            child: child,
          );
        },
        child: Row(
          children: [
            Icon(icon, color: AppColors.dark, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 16, color: AppColors.dark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
