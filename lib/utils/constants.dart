// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryBlue = Color(0xFF3B82F6); // Blue for "Create an account" and "User"
  static const Color primaryRed = Color(0xFFF87171); // Red for "Login" and "Administrator"
  static const Color textWhite = Colors.white;
  static const Color textBlack = Colors.black;
  static const Color textGray = Colors.grey;
  static const Color backgroundGray = Color(0xFFF5F5F5);

  // Strings
  static const String appName = 'Community Time Bank';

  // Text Styles
  static const TextStyle appTitleCommunityStyle = TextStyle(
    color: textWhite,
    fontSize: 60,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle appTitleTimeBankStyle = TextStyle(
    color: textWhite,
    fontSize: 55,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: textWhite,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle titleStyle = TextStyle(
    color: textBlack,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: textGray,
    fontSize: 16,
  );

  static const TextStyle linkStyle = TextStyle(
    color: primaryBlue,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}