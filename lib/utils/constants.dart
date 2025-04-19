import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryRed = Color(0xFFF87171);
  static const Color textWhite = Colors.white;
  static const Color textBlack = Colors.black;
  static const Color textGray = Colors.grey;
  static const Color backgroundGray = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color starColor = Colors.amber;

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
    fontWeight: FontWeight.normal,
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

  static const TextStyle cardTitleStyle = TextStyle(
    color: textBlack,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle cardSubtitleStyle = TextStyle(
    color: textGray,
    fontSize: 14,
  );

  // Icons
  static const IconData notificationIcon = Icons.notifications;
  static const IconData searchIcon = Icons.search;
  static const IconData homeIcon = Icons.home;
  static const IconData requestsIcon = Icons.list;
  static const IconData messagesIcon = Icons.message;
  static const IconData profileIcon = Icons.person;
}