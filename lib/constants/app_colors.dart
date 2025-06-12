import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF2AB7CA); // Soft teal for accents
  static const Color secondaryColor = Color(
    0xFF1A3C5A,
  ); // Deep navy for secondary elements
  static const Color darkBackgroundColor = Color(
    0xFF1C2526,
  ); // Dark charcoal for background
  static const MaterialColor gray = MaterialColor(0xFF8C8C8C, {
    50: Color(0xFFF9FAFB), // Very light gray for subtle backgrounds
    100: Color(0xFFF1F2F4), // Light gray for cards or sections
    200: Color(0xFFE5E7EB), // Neutral gray for dividers
    300: Color(0xFFD1D5DB), // Mid-light gray for hover states
    400: Color(0xFFB0B7C3), // Mid-gray for secondary text
    500: Color(0xFF8C8C8C), // Neutral gray for primary text
    600: Color(0xFF6B7280), // Darker gray for emphasis
    700: Color(0xFF4B5563), // Dark gray for strong contrast
    800: Color(0xFF374151), // Very dark gray for bold elements
    850: Color(0xFF2D3748), // Near-black gray for subtle accents
    900: Color(0xFF1F2A44), // Deepest gray for backgrounds or text
  });
}
