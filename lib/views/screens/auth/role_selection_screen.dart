// lib/views/screens/auth/role_selection_screen.dart
import 'package:flutter/material.dart';
import '../../../models/navigation_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/routes.dart';
import '../../widgets/custom_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String? initialRole;

  const RoleSelectionScreen({super.key, this.initialRole});

  void _navigateToSignup() {
    print('Navigating to Signup with role: $initialRole');
    NavigationService().navigateTo(Routes.signup, arguments: initialRole);
  }

  void _navigateToLogin() {
    print('Navigating to Login with role: $initialRole');
    NavigationService().navigateTo(Routes.login, arguments: initialRole);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the AppBar completely to match the image
      body: Container(
        decoration: const BoxDecoration(
          // Change to dark overlay on image of people shaking hands
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
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
              children: [
                // Push the title down from the top
                const Spacer(flex: 2),

                // Community Time Bank text in white
                // const Text(
                //   'Community',
                //   style: TextStyle(
                //     color: Colors.white,
                //     fontSize: 36,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // const Text(
                //   'Time Bank',
                //   style: TextStyle(
                //     color: Colors.white,
                //     fontSize: 36,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),

                // Push buttons to bottom of screen
                const Spacer(flex: 4),

                // Blue "Create an account" button
                CustomButton(
                  text: 'Create an account',
                  color: Colors.blue,
                  onPressed: _navigateToSignup,
                ),
                const SizedBox(height: 16),

                // Red "Login" button
                CustomButton(
                  text: 'Login',
                  color: Colors.red,
                  onPressed: _navigateToLogin,
                ),

                // Small space at bottom for home indicator
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}