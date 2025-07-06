import 'package:escort/style/app_size.dart';
import 'package:escort/style/textstyle.dart';
import 'package:flutter/material.dart';

// Enum to classify device types
enum FormFactorType { mobile, tablet, desktop }

extension StyleContext on BuildContext {
  MediaQueryData get mq => MediaQuery.of(this);
  double get width => mq.size.width;
  double get height => mq.size.height;

  ThemeData get theme => Theme.of(this);

  // Determine device type based on standard screen width breakpoints
  FormFactorType get formFactor {
    if (width < 600) {
      return FormFactorType.mobile;
    } else if (width < 1024) {
      return FormFactorType.tablet;
    } else {
      return FormFactorType.desktop;
    }
  }

  bool get isMobile => formFactor == FormFactorType.mobile;
  bool get isTablet => formFactor == FormFactorType.tablet;
  bool get isDesktop => formFactor == FormFactorType.desktop;
  bool get isDesktopOrTablet => isTablet || isDesktop;

  // Text styles adjusted per device type
  Textstyle get textStyle {
    switch (formFactor) {
      case FormFactorType.mobile:
        return SmallTextStyle();
      case FormFactorType.tablet:
        return MediumTextStyle(); // Assuming a MediumTextStyle exists or can be added
      case FormFactorType.desktop:
        return LargeTextStyle();
    }
  }

  // Insets adjusted per device type
  AppInsets get insets {
    switch (formFactor) {
      case FormFactorType.mobile:
        return SmallInsets();
      case FormFactorType.tablet:
        return MediumInsets(); // Assuming a MediumInsets exists or can be added
      case FormFactorType.desktop:
        return LargeInsets();
    }
  }

  ColorScheme get colorscheme => theme.colorScheme;

  // Navigate to a screen using the current context
  void navigateToScreen(Widget screen) {
    Navigator.push(this, MaterialPageRoute(builder: (_) => screen));
  }

  // Check if the app is in dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // Get screen size
  Size get screenSize => mq.size;

  // Get screen height
  double get screenHeight => mq.size.height;

  // Get screen width
  double get screenWidth => mq.size.width;
}
