// lib/models/firebase_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  Future<UserModel?> getUser(String uid) async {
    try {
      debugPrint('Fetching user with UID: $uid');
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        debugPrint('User data found: ${doc.data()}');
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid: uid);
      }
      debugPrint('No user found with UID: $uid');
      return null;
    } catch (e) {
      debugPrint('Error fetching user from Firestore: $e');
      rethrow;
    }
  }

  Future<void> updateWelcomePopupFlag(String uid, bool hasSeen) async {
    try {
      debugPrint('Updating welcome popup flag for UID: $uid to $hasSeen');
      await _firestore.collection('users').doc(uid).update({
        'hasSeenWelcomePopup': hasSeen,
      });
      debugPrint('Welcome popup flag updated successfully');
    } catch (e) {
      debugPrint('Error updating welcome popup flag: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getRecommendedUsers(String currentUserId, List<String> skillsWantToLearn) async {
    try {
      debugPrint('Fetching recommended users for user ID: $currentUserId');
      debugPrint('Skills to learn: $skillsWantToLearn');

      if (skillsWantToLearn.isEmpty) {
        debugPrint('No skills to learn provided, returning empty list');
        return [];
      }

      QuerySnapshot querySnapshot = await _firestore.collection('users').get();

      List<UserModel> allUsers = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, uid: doc.id))
          .where((user) => user.uid != currentUserId) // Exclude the current user
          .toList();

      List<UserModel> recommendedUsers = allUsers.where((user) {
        return user.skillsCanTeach.any((skill) => skillsWantToLearn.contains(skill));
      }).toList();

      recommendedUsers.sort((a, b) => b.rating.compareTo(a.rating));

      debugPrint('Found ${recommendedUsers.length} recommended users');
      return recommendedUsers;
    } catch (e) {
      debugPrint('Error fetching recommended users: $e');
      rethrow;
    }
  }

  Future<String> uploadProfilePicture(String uid, File image) async {
    try {
      debugPrint('Uploading profile picture for UID: $uid');
      final ref = _storage.ref().child('profile_pictures/$uid.jpg');
      await ref.putFile(image);
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('Profile picture uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      rethrow;
    }
  }
}