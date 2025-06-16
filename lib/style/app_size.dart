class Insets {
  static const double maxWidth = 1280;
  static double get med => 12;
  static double get xs => 4;
  static double get xl => 20;
  static double get xxl => 32;
  static double get xxxl => 80;
  static double get lg => 16;
  static double get sm => 8;
}

abstract class AppInsets {
  double get padding;
  double get appBarHeight;
  double get cardpadding;
  double get gap;
}

class LargeInsets extends AppInsets {
  @override
  double get padding => 80;

  @override
  double get appBarHeight => 70;

  @override
  double get cardpadding => Insets.xl;

  @override
  double get gap => 120;
}

class SmallInsets extends AppInsets {
  @override
  double get padding => 16;

  @override
  double get appBarHeight => 56;

  @override
  double get cardpadding => Insets.lg;

  @override
  double get gap => 120;
}

class MediumInsets extends AppInsets {
  @override
  double get padding => 60;

  @override
  double get appBarHeight => 64;

  @override
  double get cardpadding => Insets.med;

  @override
  double get gap => 120;
}

class Sizes {
  // Padding and Margin Sizes
  static const double xs = 4.0; // Extra small padding/margin
  static const double sm = 8.0; // Small padding/margin
  static const double md = 16.0; // Medium padding/margin
  static const double lg = 24.0; // Large padding/margin
  static const double xl = 32.0; // Extra large padding/margin

  // Icon Sizes
  static const double iconXs = 12.0; // Extra small icon
  static const double iconSm = 16.0; // Small icon
  static const double iconMd = 24.0; // Medium icon
  static const double iconLg = 32.0; // Large icon

  // Font Sizes
  static const double fontSizeSm = 14.0; // Small font size
  static const double fontSizeMd = 16.0; // Medium font size
  static const double fontSizeLg = 18.0; // Large font size

  // Button Sizes
  static const double buttonHeight = 48.0; // Standard button height
  static const double buttonRadius = 12.0; // Button corner radius
  static const double buttonWidth = 120.0; // Minimum button width
  static const double buttonElevation = 4.0; // Button elevation

  // AppBar Height
  static const double appBarHeight = 56.0; // Standard AppBar height

  // Image Sizes
  static const double imageSize =
      100.0; // Default square image size for thumbnails

  // Border Radius
  static const double borderRadiusSm = 4.0; // Small border radius
  static const double borderRadiusMd = 8.0; // Medium border radius
  static const double borderRadiusLg = 12.0; // Large border radius

  // Default Spacing Between Sections
  static const double defaultSpace = 24.0; // Small section spacing
  static const double spaceBtwItems = 16.0; // Medium section spacing
  static const double spaceBtwSections = 32.0; // Large section spacing

  // Product Item Dimensions
  static const double productItemWidth = 160.0; // Width for product cards
  static const double productItemHeight = 160.0; // Height for product cards
  static const double productImageSize = 120.0; // Product image size
  static const double productImageRadius = 16.0;

  // Divider Height
  static const double dividerHeight = 1.0; // Standard divider height

  // Input Field
  static const double inputFieldHeight = 20.0; // Input field height
  static const double inputFieldRadius = 12.0; // Input field corner radius
  static const double spaceBtwinputFields = 16.0;

  // Card Sizes
  static const double cardRadiusSm = 10.0; // Small card height
  static const double cardRadiusMd = 12.0; // Medium card height
  static const double cardRadiusLg = 160.0; // Large card height
  static const double cardRadiusXs = 6.0; // Small card width
  static const double cardElevation = 2.0; // Large card width

  //Image carousel height
  static const double imageCarouselHeight = 200.0;

  //loading indicator size
  static const double loadingIndicatorSize = 36.0;

  //Grid view spacing
  static const double gridViewSpacing = 16.0;
}
