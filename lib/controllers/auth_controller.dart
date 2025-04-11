// lib/controllers/auth_controller.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

  // Sign up a new user
  Future<String?> signUp({
    required String fullName,
    required String email,
    required String password,
    required List<String> skillsCanTeach,
    required List<String> skillsWantToLearn,
    required String role,
    required Map<String, List<String>> availability,
    File? profilePicture,
    required double rating,
  }) async {
    try {
      print("Starting signup for email: $email");
      print("Skills Can Teach: $skillsCanTeach");
      print("Skills Want to Learn: $skillsWantToLearn");
      print("Role: $role");
      print("Availability: $availability");
      print("Profile Picture: ${profilePicture?.path}");
      print("Rating: $rating");

      // Step 1: Create user in Firebase Auth
      print("Attempting to create user with email: $email");
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String userId = userCredential.user!.uid;
      print("User created in Firebase Auth with UID: $userId");

      // Step 2: Upload profile picture if provided
      String profilePictureUrl = 'https://picsum.photos/300'; // Default URL
      if (profilePicture != null) {
        print("Uploading profile picture for UID: $userId");
        try {
          profilePictureUrl = await _uploadProfilePicture(userId, profilePicture);
        } catch (e) {
          print("Error uploading profile picture: $e");
          // Use default URL if upload fails
          profilePictureUrl = 'https://picsum.photos/300';
        }
      }

      // Step 3: Save user data to Firestore
      Map<String, dynamic> userData = {
        'fullName': fullName,
        'email': email,
        'skillsCanTeach': skillsCanTeach,
        'skillsWantToLearn': skillsWantToLearn,
        'role': role,
        'availability': availability,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'profilePictureUrl': profilePictureUrl, // Always set profilePictureUrl
        'timeCredits': 1, // Ensure this field is set
        'hasSeenWelcomePopup': false, // Ensure this field is set
        'location': 'Not specified', // Ensure this field is set
        'bio': 'No bio provided.', // Ensure this field is set
      };

      await _firestore.collection('users').doc(userId).set(userData);
      print("User data saved to Firestore for UID: $userId");

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "The email address is already in use. Please sign in instead.";
      }
      return "Error during signup: ${e.message}";
    } catch (e) {
      print("Error during signup: $e");
      return e.toString();
    }
  }

  // Sign in an existing user
  Future<String?> signIn(String email, String password) async {
    try {
      print("Starting signin for email: $email");
      print("Attempting to sign in with email: $email");

      // Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      String userId = userCredential.user!.uid;
      print("User signed in successfully with UID: $userId");

      return null; // Success
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during signin: ${e.code} - ${e.message}");
      if (e.code == 'user-not-found') {
        return "No user found with this email. Please sign up.";
      } else if (e.code == 'wrong-password') {
        return "Incorrect password. Please try again.";
      } else if (e.code == 'invalid-email') {
        return "The email address is invalid.";
      }
      return "Error during signin: ${e.message}";
    } catch (e) {
      print("Unexpected error during signin: $e");
      return "An unexpected error occurred: $e";
    }
  }

  // Upload profile picture to Firebase Storage
  Future<String> _uploadProfilePicture(String userId, File profilePicture) async {
    try {
      // Verify the file exists
      if (!await profilePicture.exists()) {
        throw Exception("Profile picture file does not exist at ${profilePicture.path}");
      }

      // Define the storage reference
      firebase_storage.Reference ref = _storage
          .ref()
          .child('profile_pictures/$userId/profile.jpg');
      print("Uploading to Firebase Storage path: ${ref.fullPath}");

      // Upload the file
      await ref.putFile(profilePicture);
      print("Profile picture uploaded successfully");

      // Get the download URL
      String downloadUrl = await ref.getDownloadURL();
      print("Profile picture URL: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("Error uploading profile picture: $e");
      throw Exception("Failed to upload profile picture: $e");
    }
  }
}