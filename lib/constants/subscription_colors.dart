import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubscriptionColors {
  static final Color primaryColor = Color(
    0xFF611BF8,
  ); // primary-700 from Tailwind config
  static final Color backgroundStart = Color(0xFFF7F7F7); // neutral-50
  static final Color backgroundEnd = Colors.white;

  static final TextStyle titleStyle = GoogleFonts.lato(
    fontSize: 30, // Matches text-3xl
    fontWeight: FontWeight.bold,
    color: Colors.grey[900], // text-gray-900
  );

  static final TextStyle cardTitleStyle = GoogleFonts.lato(
    fontSize: 24, // Matches text-2xl
    fontWeight: FontWeight.bold,
    color: Colors.grey[900], // text-gray-900
  );

  static final TextStyle subtitleStyle = GoogleFonts.openSans(
    fontSize: 18, // Matches text-lg
    color: Colors.grey[600], // text-gray-600
  );

  static final TextStyle bodyStyle = GoogleFonts.openSans(
    fontSize: 16, // Matches base font size
    color: Colors.grey[700], // text-gray-700
  );

  static final TextStyle priceStyle = TextStyle(
    fontSize: 36, // Matches text-4xl
    fontWeight: FontWeight.bold,
    color: primaryColor, // text-primary-600
  );
}
