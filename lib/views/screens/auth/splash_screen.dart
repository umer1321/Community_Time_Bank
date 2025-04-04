// lib/views/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../utils/routes.dart';

import '../../widgets/custom_button.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _selectedRole; // To store the selected role ("User" or "Administrator")

  void _selectRoleAndNavigate(String role) {
    setState(() {
      _selectedRole = role;
    });
    // Navigate to Role Selection Screen with the selected role
    Navigator.pushReplacementNamed(
      context,
      Routes.roleSelection,
      arguments: role,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpeg'), // Add your image here
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black54, // Dark overlay for readability
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Title with "Community" bold and "Time Bank" regular on a new line
                Expanded(
                  child: Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Community\n',
                            style: AppConstants.appTitleCommunityStyle,
                          ),
                          TextSpan(
                            text: 'Time Bank',
                            style: AppConstants.appTitleTimeBankStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Role selection buttons
                CustomButton(
                  text: 'User',
                  color: AppConstants.primaryBlue,
                  onPressed: () => _selectRoleAndNavigate('User'),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Administrator',
                  color: AppConstants.primaryRed,
                  onPressed: () => _selectRoleAndNavigate('Administrator'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}