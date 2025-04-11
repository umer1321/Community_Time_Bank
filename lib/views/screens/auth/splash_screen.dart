// lib/views/screens/auth/splash_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart'; // For compute
import '../../../models/navigation_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/routes.dart';
import '../../widgets/custom_button.dart';

// Function to fetch user data in a background isolate
Future<Map<String, dynamic>?> fetchUserData(String uid) async {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  return userDoc.exists ? userDoc.data() : null;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _selectedRole;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Perform auth check after the first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        try {
          // Offload Firestore query to a background isolate
          final userData = await compute(fetchUserData, user.uid);

          if (!mounted) return;

          if (userData != null) {
            final role = userData['role'] as String?;

            if (role == null) {
              print('User role is null, redirecting to signup to complete profile');
              _safeNavigate(Routes.signup);
              return;
            }

            if (role == 'Admin') {
              print('User is Admin, navigating to Admin Dashboard');
              _safeNavigate(Routes.adminDashboard);
              return;
            } else if (role == 'User') {
              print('User is a regular user, navigating to Home');
              _safeNavigate(Routes.home);
              return;
            } else {
              print('Invalid role: $role, redirecting to role selection');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              return;
            }
          } else {
            print('User document does not exist, redirecting to signup');
            _safeNavigate(Routes.signup);
            return;
          }
        } catch (e) {
          print('Firestore error: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error fetching user data: $e')),
            );
          }
        }
      } else {
        // No user logged in, show role selection buttons
        print('No user logged in, showing role selection buttons');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Auth check error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error: $e')),
        );
      }
    }
  }

  void _safeNavigate(String route, {String? role}) {
    if (!mounted) return;

    print('Planning navigation to $route${role != null ? " with role: $role" : ""}');

    // Schedule navigation after the current frame is fully rendered
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        print('Executing navigation to $route${role != null ? " with role: $role" : ""}');
        if (role != null) {
          NavigationService().navigateToAndRemove(route, arguments: role);
        } else {
          NavigationService().navigateToAndRemove(route);
        }
      } catch (e) {
        print('Navigation error: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigation error: $e')),
          );
        }
      }
    });
  }

  void _selectRole(String role) {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _selectedRole = role;
    });

    _safeNavigate(Routes.roleSelection, role: role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpeg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  CustomButton(
                    text: 'User',
                    color: AppConstants.primaryBlue,
                    onPressed: () => _selectRole('User'),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Administrator',
                    color: AppConstants.primaryRed,
                    onPressed: () => _selectRole('Admin'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}