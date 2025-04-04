// lib/models/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      debugPrint('Attempting to create user with email: $email');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('User created successfully: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      debugPrint('Error during signup in FirebaseService: $e');
      if (e is FirebaseAuthException) {
        debugPrint('FirebaseAuthException code: ${e.code}');
        debugPrint('FirebaseAuthException message: ${e.message}');
      }
      rethrow;
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      debugPrint('Attempting to sign in with email: $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('User signed in successfully: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      debugPrint('Error during signin in FirebaseService: $e');
      if (e is FirebaseAuthException) {
        debugPrint('FirebaseAuthException code: ${e.code}');
        debugPrint('FirebaseAuthException message: ${e.message}');
      }
      rethrow;
    }
  }

  // Save user data to Firestore
  Future<void> saveUser(UserModel user) async {
    try {
      debugPrint('Saving user to Firestore: ${user.toMap()}');
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      debugPrint('User saved successfully to Firestore');
    } catch (e) {
      debugPrint('Error saving user to Firestore: $e');
      if (e is FirebaseException) {
        debugPrint('FirebaseException code: ${e.code}');
        debugPrint('FirebaseException message: ${e.message}');
      }
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      debugPrint('Fetching user with UID: $uid');
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        debugPrint('User data found: ${doc.data()}');
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      debugPrint('No user found with UID: $uid');
      return null;
    } catch (e) {
      debugPrint('Error fetching user from Firestore: $e');
      rethrow;
    }
  }
}