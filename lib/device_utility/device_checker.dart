import 'package:escort/style/app_size.dart';
import 'package:escort/style/textstyle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

//checks whether the device is either a mobile , desktop or a tablet
enum FormFactorType { mobile, tablet, desktop }

extension StyleContext on BuildContext {
  MediaQueryData get mq => MediaQuery.of(this);
  double get width => mq.size.width;
  double get height => mq.size.height;

  ThemeData get theme => Theme.of(this);

  FormFactorType get formFactor {
    if (width < 600) {
      return FormFactorType.mobile;
    } else if (width < 900) {
      return FormFactorType.tablet;
    } else {
      return FormFactorType.desktop;
    }
  }

  bool get isMobile => formFactor == FormFactorType.mobile;
  bool get isTablet => formFactor == FormFactorType.tablet;
  bool get isDesktop => formFactor == FormFactorType.desktop;
  bool get isDesktopOrTablet => isTablet || isDesktop;

  Textstyle get textStyle {
    switch (formFactor) {
      case FormFactorType.mobile:
      case FormFactorType.tablet:
        return SmallTextStyle();
      case FormFactorType.desktop:
        return LargeTextStyle();
    }
  }

  AppInsets get insets {
    switch (formFactor) {
      case FormFactorType.mobile:
        return SmallInsets();
      case FormFactorType.tablet:
      case FormFactorType.desktop:
        return LargeInsets();
    }
  }

  //AppLocalizations get texts =>
  //AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));

  ColorScheme get colorscheme => theme.colorScheme;

  // Navigate to a screen
  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // Check if the app is in dark mode
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Get screen size
  static Size screenSize() {
    return MediaQuery.of(Get.context!).size;
  }

  // Get screen height
  static double screenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  // Get screen width
  static double screenWidth() {
    return MediaQuery.of(Get.context!).size.width;
  }
}
