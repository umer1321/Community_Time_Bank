// lib/views/screens/auth/role_selection_screen.dart
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../utils/routes.dart';

import '../../widgets/custom_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the selected role passed from Splash Screen
    final String? role = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpeg'), // Same background as Splash
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black54,
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
                // Buttons at the bottom
                CustomButton(
                  text: 'Create an account',
                  color: AppConstants.primaryBlue,
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.signup, arguments: role);
                  },
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Login',
                  color: AppConstants.primaryRed,
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.login, arguments: role);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}