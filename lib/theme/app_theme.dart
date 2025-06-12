import 'package:escort/constants/app_colors.dart';
import 'package:escort/style/app_size.dart';
import 'package:flutter/material.dart';

class AppTheme {
  final String fontFamily;

  static var darkTheme;
  static var lightTheme;

  AppTheme({required this.fontFamily});

  ThemeData get dark {
    return _getThemeData(
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryColor,
        surface: AppColors.gray[850]!,
        outline: AppColors.gray[800]!,
        outlineVariant: AppColors.gray[700]!,
        onSurface: AppColors.gray[300]!,
        onSurfaceVariant: AppColors.gray[400]!,
        tertiary: AppColors.gray[900]!,
      ),
      scaffoldBackgroundColor: AppColors.darkBackgroundColor,
      elevatedButtonTextStyle: _darkElevatedButtonTextStyle,
      outlinedButtonTextStyle: _darkOutlinedButtonTextStyle,
      appBarTheme: AppBarTheme(color: AppColors.gray[900]!.withOpacity(0.3)),
    );
  }

  ThemeData get light {
    return _getThemeData(
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryColor, // Warm off-white
        surface: const Color(0xFFEDEDEB), // Light neutral gray
        outline: const Color(0xFFD4D4D1), // Mid-tone gray
        outlineVariant: AppColors.gray[400]!, // Warm dark gray
        onSurface: const Color(0xFF525252), // Medium gray
        onSurfaceVariant: AppColors.gray[600]!, // #6B7280
        tertiary: AppColors.gray[900]!, // #1F2A44
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F4),
      elevatedButtonTextStyle: _lightElevatedButtonTextStyle,
      outlinedButtonTextStyle: _lightOutlinedButtonTextStyle,
      appBarTheme: AppBarTheme(color: const Color(0xFFEDEDEB).withOpacity(0.3)),
    );
  }

  ThemeData _getThemeData({
    required ColorScheme colorScheme,
    required WidgetStateProperty<TextStyle> elevatedButtonTextStyle,
    required WidgetStateProperty<TextStyle> outlinedButtonTextStyle,
    required Color scaffoldBackgroundColor,
    required AppBarTheme appBarTheme,
  }) {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: appBarTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          fixedSize: const WidgetStatePropertyAll(Size.fromHeight(40)),
          backgroundColor: _primaryButtonStates,
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Insets.xl, vertical: 10),
          ),
          textStyle: elevatedButtonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          fixedSize: const WidgetStatePropertyAll(Size.fromHeight(40)),
          side: _outlineButtonStates,
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Insets.xl, vertical: 10),
          ),
          textStyle: outlinedButtonTextStyle,
        ),
      ),
    );
  }

  WidgetStatePropertyAll<TextStyle> get _darkElevatedButtonTextStyle =>
      WidgetStatePropertyAll<TextStyle>(
        TextStyle(
          color: AppColors.gray[100]!, // #F9FAFB
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
      );

  WidgetStatePropertyAll<TextStyle> get _lightElevatedButtonTextStyle =>
      WidgetStatePropertyAll<TextStyle>(
        TextStyle(
          color: AppColors.gray[900]!, // #1F2A44 for contrast on teal
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
      );

  WidgetStatePropertyAll<TextStyle> get _darkOutlinedButtonTextStyle =>
      WidgetStatePropertyAll<TextStyle>(
        TextStyle(
          color: AppColors.gray[100]!, // #F9FAFB
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
      );

  WidgetStatePropertyAll<TextStyle> get _lightOutlinedButtonTextStyle =>
      WidgetStatePropertyAll<TextStyle>(
        TextStyle(
          color: const Color(0xFF3F3F3F), // Warm dark gray
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
      );
}

final _primaryButtonStates = WidgetStateProperty.resolveWith((states) {
  if (states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.pressed)) {
    return const Color(0xFF219EAC).withOpacity(0.7); // Muted teal
  }
  return AppColors.primaryColor; // #2AB7CA
});

final _outlineButtonStates = WidgetStateProperty.resolveWith((states) {
  if (states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.pressed)) {
    return BorderSide(color: const Color(0xFF219EAC).withOpacity(0.7));
  }
  return const BorderSide(color: Color(0xFF219EAC));
});
