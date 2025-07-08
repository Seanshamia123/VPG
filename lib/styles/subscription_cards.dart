import 'package:flutter/material.dart';

class SubscriptionColors {
  // Primary colors
  static const Color primaryColor = Color(0xFFFFD700); // Bright gold
  static const Color secondaryColor = Color(0xFF000000); // Black
  static const Color accentColor = Color(0xFFFFA500); // Orange gold for accents
  
  // Background colors
  static const Color backgroundStart = Color(0xFF1A1A1A); // Dark charcoal
  static const Color backgroundEnd = Color(0xFF000000); // Pure black
  
  // Card colors
  static const Color cardBackground = Color(0xFF2A2A2A); // Dark gray for cards
  static const Color cardBorder = Color(0xFFFFD700); // Bright gold border
  static const Color popularCardBackground = Color(0xFF1A1A1A); // Darker for popular
  static const Color popularCardBorder = Color(0xFFFFA500); // Orange gold for popular
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFD700); // Bright gold
  static const Color textSecondary = Color(0xFFFFFFFF); // White
  static const Color textTertiary = Color(0xFFCCCCCC); // Light gray
  static const Color textOnButton = Color(0xFF000000); // Black text on gold button
  
  // Button colors
  static const Color buttonBackground = Color(0xFFFFD700); // Bright gold
  static const Color buttonHover = Color(0xFFFFA500); // Orange gold on hover
  static const Color buttonPressed = Color(0xFFB8860B); // Dark goldenrod when pressed
  
  // Text styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    color: textTertiary,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: textSecondary,
  );
  
  static const TextStyle priceStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle featureStyle = TextStyle(
    fontSize: 14,
    color: textSecondary,
  );
  
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textOnButton,
  );
  
  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle cardDescriptionStyle = TextStyle(
    fontSize: 14,
    color: textTertiary,
  );
  
  static const TextStyle popularBadgeStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: textOnButton,
  );
}