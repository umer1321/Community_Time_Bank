// lib/controllers/auth_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../models/firebase_service.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseService _firebaseService = FirebaseService();

  // Sign up a new user
  Future<String?> signUp({
    required String fullName,
    required String email,
    required String password,
    required List<String> skillsCanTeach,
    required List<String> skillsWantToLearn,
    required String role,
    required Map<String, List<String>> availability,
  }) async {
    try {
      debugPrint('Starting signup for email: $email');
      debugPrint('Skills Can Teach: $skillsCanTeach');
      debugPrint('Skills Want to Learn: $skillsWantToLearn');
      debugPrint('Role: $role');
      debugPrint('Availability: $availability');

      // Create user in Firebase Auth
      User? user = await _firebaseService.signUp(email, password);
      if (user != null) {
        debugPrint('User created in Firebase Auth with UID: ${user.uid}');
        // Create UserModel
        UserModel userModel = UserModel(
          uid: user.uid,
          fullName: fullName,
          email: email,
          skillsCanTeach: skillsCanTeach,
          skillsWantToLearn: skillsWantToLearn,
          role: role,
          availability: availability,
        );
        debugPrint('UserModel created: ${userModel.toMap()}');
        // Save user data to Firestore
        await _firebaseService.saveUser(userModel);
        debugPrint('Signup completed successfully');
        return null; // Success
      }
      debugPrint('Failed to create user in Firebase Auth');
      return 'Failed to create user';
    } catch (e) {
      debugPrint('Error during signup: $e');
      return e.toString();
    }
  }

  // Sign in an existing user
  Future<String?> signIn(String email, String password) async {
    try {
      debugPrint('Starting signin for email: $email');
      User? user = await _firebaseService.signIn(email, password);
      if (user != null) {
        debugPrint('User signed in successfully with UID: ${user.uid}');
        return null; // Success (skip fetching user data for now)
      }
      debugPrint('Failed to sign in');
      return 'Failed to sign in';
    } catch (e) {
      debugPrint('Error during signin: $e');
      return e.toString();
    }
  }
}