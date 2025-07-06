import 'package:escort/styles/app_size.dart';
import 'package:flutter/material.dart';

class SpacingStyles {
  // Existing static padding
  static const EdgeInsetsGeometry paddingWithAppBarHeight = EdgeInsets.only(
    top: Sizes.appBarHeight,
    left: Sizes.defaultSpace,
    bottom: Sizes.defaultSpace,
    right: Sizes.defaultSpace,
  );

  // New dynamic padding based on screen width
  static EdgeInsetsGeometry getDynamicPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.05; // 5% of screen width
    return EdgeInsets.all(padding);
  }

  // Additional padding variations
  static EdgeInsetsGeometry getPaddingWithoutAppBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.05;
    return EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2);
  }
}
