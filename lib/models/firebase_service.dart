// lib/models/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../models/review_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //// For images load
  Future<void> migrateProfilePictureUrls() async {
    try {
      debugPrint('Starting profile picture URL migration...');
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['profilePictureUrl'] == 'https://via.placeholder.com/300') {
          await _firestore.collection('users').doc(doc.id).update({
            'profilePictureUrl': 'https://picsum.photos/300',
          });
          debugPrint('Updated profilePictureUrl for UID: ${doc.id}');
        }
      }
      // Also update public_profiles
      snapshot = await _firestore.collection('public_profiles').get();
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['profilePictureUrl'] == 'https://via.placeholder.com/300') {
          await _firestore.collection('public_profiles').doc(doc.id).update({
            'profilePictureUrl': 'https://picsum.photos/300',
          });
          debugPrint('Updated profilePictureUrl in public_profiles for UID: ${doc.id}');
        }
      }
      debugPrint('Profile picture URL migration completed.');
    } catch (e) {
      debugPrint('Error during profile picture URL migration: $e');
      rethrow;
    }
  }

  /// Chat system
  // Create a new conversation between two users if it doesn't exist
  Future<String> createConversation(String currentUserId, String otherUserId) async {
    try {
      // Check if a conversation already exists between the two users
      QuerySnapshot existingConversations = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .get();

      String? conversationId;
      for (var doc in existingConversations.docs) {
        List<String> participants = List<String>.from(doc['participants']);
        if (participants.contains(otherUserId)) {
          conversationId = doc.id;
          break;
        }
      }

      // If no conversation exists, create a new one
      if (conversationId == null) {
        DocumentReference docRef = await _firestore.collection('conversations').add({
          'participants': [currentUserId, otherUserId],
          'lastMessage': '',
          'lastMessageTime': Timestamp.now(),
        });
        conversationId = docRef.id;
        debugPrint('Created new conversation with ID: $conversationId');
      } else {
        debugPrint('Conversation already exists with ID: $conversationId');
      }

      return conversationId;
    } catch (e) {
      debugPrint('Error creating conversation between $currentUserId and $otherUserId: $e');
      rethrow;
    }
  }

  // Fetch all conversations for the current user
  Stream<List<ConversationModel>> getConversations(String currentUserId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ConversationModel> conversations = [];
      for (var doc in snapshot.docs) {
        List<String> participants = List<String>.from(doc['participants']);
        String otherUserId = participants.firstWhere((id) => id != currentUserId);
        UserModel otherUser = await getUserById(otherUserId);
        conversations.add(ConversationModel.fromDocument(doc, otherUser));
      }
      return conversations;
    });
  }

  // Fetch messages for a specific conversation
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromDocument(doc)).toList();
    });
  }

  // Send a message in a conversation
  Future<void> sendMessage(String conversationId, MessageModel message, String currentUserId, String otherUserId) async {
    try {
      // Add the message to the messages subcollection
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(message.toMap());

      // Update the conversation's last message and timestamp
      await _firestore.collection('conversations').doc(conversationId).set({
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp,
        'participants': [currentUserId, otherUserId],
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      List<UserModel> users = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid: doc.id);
      }).toList();
      debugPrint('Fetched ${users.length} users from Firestore');
      return users;
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      rethrow;
    }
  }

  // Get user by ID
  Future<UserModel> getUserById(String userId) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      throw Exception('User not found for ID: $userId');
    }
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid: userId);
  }

  String? getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('No user is currently logged in.');
      return null;
    }
    return user.uid;
  }

  // Fetch a user by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      await migrateUserAvailability(uid); // Migrate on first access
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        debugPrint('User document does not exist for UID: $uid');
        return null;
      }
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid: uid);
    } catch (e) {
      debugPrint('Error fetching user with UID $uid: $e');
      rethrow;
    }
  }

  // Sync user data to public_profiles
  Future<void> syncUserToPublicProfile(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        debugPrint('User document does not exist for UID: $uid, cannot sync to public_profiles');
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      await _firestore.collection('public_profiles').doc(uid).set(userData, SetOptions(merge: true));
      debugPrint('Synced user data to public_profiles for UID: $uid');
    } catch (e) {
      debugPrint('Error syncing user to public_profiles for UID $uid: $e');
      rethrow;
    }
  }

  // Update user document with missing fields
  Future<void> updateUserWithMissingFields(String uid) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(uid);
      DocumentSnapshot doc = await userRef.get();
      if (!doc.exists) {
        debugPrint('User document does not exist for UID: $uid');
        return;
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> updates = {};

      if (!data.containsKey('profilePictureUrl')) {
        updates['profilePictureUrl'] = 'https://picsum.photos/300';
      }
      if (!data.containsKey('location')) {
        updates['location'] = 'Not specified';
      }
      if (!data.containsKey('bio')) {
        updates['bio'] = 'No bio provided.';
      }
      if (!data.containsKey('timeCredits')) {
        updates['timeCredits'] = 1;
      }
      if (!data.containsKey('availability')) {
        updates['availability'] = [];
      }

      if (updates.isNotEmpty) {
        await userRef.update(updates);
        debugPrint('Updated user document for UID: $uid with fields: $updates');
      } else {
        debugPrint('No updates needed for user document UID: $uid');
      }

      await syncUserToPublicProfile(uid);
    } catch (e) {
      debugPrint('Error updating user document for UID $uid: $e');
      rethrow;
    }
  }

  // Migrate user availability data from Map<String, List<String>> to List<String>
  Future<void> migrateUserAvailability(String userId) async {
    try {
      debugPrint('Starting availability migration for user $userId');
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        debugPrint('User document does not exist for UID: $userId');
        return;
      }

      if (!doc.data().toString().contains('availability')) {
        debugPrint('No availability field in user document for UID: $userId');
        await _firestore.collection('users').doc(userId).update({
          'availability': [],
        });
        await syncUserToPublicProfile(userId);
        debugPrint('Added empty availability list for user $userId');
        return;
      }

      var availabilityData = doc['availability'];
      debugPrint('Raw availability data for user $userId: $availabilityData (type: ${availabilityData.runtimeType})');

      List<String> newAvailability = [];

      if (availabilityData is Map) {
        // Old format: Map<String, List<String>> (e.g., {"2025-04-13": ["09:00", "10:00"]})
        Map<String, dynamic> availabilityMap = availabilityData as Map<String, dynamic>;
        newAvailability = availabilityMap.keys.toList();
        debugPrint('Migrating availability for user $userId from Map to List: $newAvailability');
      } else if (availabilityData is List) {
        // Already in the new format (List<String>)
        debugPrint('Availability for user $userId is already in List format: $availabilityData');
        return;
      } else {
        debugPrint('Unexpected availability format for user $userId: $availabilityData (type: ${availabilityData.runtimeType})');
        newAvailability = [];
      }

      // Update the user's availability to the new format
      await _firestore.collection('users').doc(userId).update({
        'availability': newAvailability,
      });
      await syncUserToPublicProfile(userId);
      debugPrint('Successfully migrated availability for user $userId to: $newAvailability');
    } catch (e) {
      debugPrint('Error migrating user availability for user $userId: $e');
      rethrow;
    }
  }

  // Fetch recommended users

  Future<List<UserModel>> getRecommendedUsers(String currentUserId, List<String> skillsWantToLearn) async {
    try {
      debugPrint('Fetching recommended users from public_profiles for user ID: $currentUserId');
      QuerySnapshot querySnapshot = await _firestore.collection('public_profiles').get();
      List<UserModel> allUsers = [];

      // Migrate availability for each user before mapping to UserModel
      for (var doc in querySnapshot.docs) {
        String userId = doc.id;
        await migrateUserAvailability(userId); // Ensure availability is migrated
      }

      // Fetch the updated documents after migration
      querySnapshot = await _firestore.collection('public_profiles').get();
      allUsers = querySnapshot.docs
          .map((doc) {
        debugPrint('Processing user document: ${doc.id} with data: ${doc.data()}');
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid: doc.id);
      })
          .where((user) => user.uid != currentUserId)
          .toList();

      debugPrint('Total users after excluding current user from public_profiles: ${allUsers.length}');

      if (allUsers.isEmpty) {
        debugPrint('No users found in public_profiles after excluding current user, falling back to users collection');
        querySnapshot = await _firestore.collection('users').get();

        // Migrate availability for users in the users collection as well
        for (var doc in querySnapshot.docs) {
          String userId = doc.id;
          await migrateUserAvailability(userId); // Ensure availability is migrated
        }

        // Fetch the updated documents after migration
        querySnapshot = await _firestore.collection('users').get();
        allUsers = querySnapshot.docs
            .map((doc) {
          debugPrint('Processing user document from users collection: ${doc.id} with data: ${doc.data()}');
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid: doc.id);
        })
            .where((user) => user.uid != currentUserId)
            .toList();
        debugPrint('Total users after excluding current user from users collection: ${allUsers.length}');
      }

      if (skillsWantToLearn.isNotEmpty) {
        debugPrint('Filtering users based on skillsWantToLearn: $skillsWantToLearn');
        allUsers = allUsers.where((user) {
          bool matches = user.skillsCanTeach.any((skill) => skillsWantToLearn.contains(skill));
          debugPrint('User ${user.fullName} (UID: ${user.uid}) skillsCanTeach: ${user.skillsCanTeach}, matches: $matches');
          return matches;
        }).toList();
      }

      allUsers.sort((a, b) => b.rating.compareTo(a.rating));
      debugPrint('Found ${allUsers.length} recommended users after filtering');
      return allUsers;
    } catch (e) {
      debugPrint('Error fetching recommended users: $e');
      rethrow;
    }
  }

  // Update the welcome popup flag
  Future<void> updateWelcomePopupFlag(String uid, bool hasSeen) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hasSeenWelcomePopup': hasSeen,
      });
      await syncUserToPublicProfile(uid);
    } catch (e) {
      debugPrint('Error updating welcome popup flag for UID $uid: $e');
      rethrow;
    }
  }

  // Create a new skill exchange request
  Future<String> createSkillRequest({
    required String requesterUid,
    required String targetUid,
    required String skillOffered,
    required String skillWanted,
    required String skillRequested,
    required String sessionDate,
    required String sessionTime,
    required String additionalNotes,
    required bool sessionReminder,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('requests').add({
        'senderId': requesterUid,
        'receiverId': targetUid,
        'skillOffered': skillOffered,
        'skillWanted': skillWanted,
        'skillRequested': skillRequested,
        'sessionDate': sessionDate,
        'sessionTime': sessionTime,
        'additionalNotes': additionalNotes,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'sessionReminder': sessionReminder,
      });
      debugPrint('Skill request created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating skill request for senderId $requesterUid: $e');
      rethrow;
    }
  }

  // Update an existing skill exchange request
  Future<void> updateSkillRequest({
    required String requestId,
    required String sessionDate,
    required String sessionTime,
    required String additionalNotes,
    required bool sessionReminder,
  }) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'sessionDate': sessionDate,
        'sessionTime': sessionTime,
        'additionalNotes': additionalNotes,
        'sessionReminder': sessionReminder,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('Skill request updated: $requestId');
    } catch (e) {
      debugPrint('Error updating skill request $requestId: $e');
      rethrow;
    }
  }

  // Withdraw a skill exchange request
  Future<void> withdrawSkillRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'withdrawn',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('Skill request withdrawn: $requestId');
    } catch (e) {
      debugPrint('Error withdrawing skill request $requestId: $e');
      rethrow;
    }
  }

  // Fetch sent requests for a user
  Future<List<RequestModel>> getSentRequests() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      QuerySnapshot querySnapshot = await _firestore
          .collection('requests')
          .where('senderId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'accepted'])
          .orderBy('createdAt', descending: true)
          .get();

      List<RequestModel> requests = [];
      for (var doc in querySnapshot.docs) {
        RequestModel request = RequestModel.fromFirestore(doc);
        // Fetch target user data
        UserModel? targetUser = await getUser(request.receiverId);
        if (targetUser != null) {
          request.targetUser = targetUser;
          requests.add(request);
        } else {
          debugPrint('Target user not found for receiverId: ${request.receiverId}');
        }
      }
      debugPrint('Fetched ${requests.length} sent requests for senderId: ${user.uid}');
      return requests;
    } catch (e) {
      debugPrint('Error fetching sent requests for senderId ${_auth.currentUser?.uid}: $e');
      rethrow;
    }
  }

  // Fetch received requests for a user
  Future<List<RequestModel>> getReceivedRequests() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      QuerySnapshot querySnapshot = await _firestore
          .collection('requests')
          .where('receiverId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'accepted'])
          .orderBy('createdAt', descending: true)
          .get();

      List<RequestModel> requests = [];
      for (var doc in querySnapshot.docs) {
        RequestModel request = RequestModel.fromFirestore(doc);
        // Fetch sender user data
        UserModel? senderUser = await getUser(request.senderId);
        if (senderUser != null) {
          request.senderUser = senderUser;
          requests.add(request);
        } else {
          debugPrint('Sender user not found for senderId: ${request.senderId}');
        }
      }
      debugPrint('Fetched ${requests.length} received requests for receiverId: ${user.uid}');
      return requests;
    } catch (e) {
      debugPrint('Error fetching received requests for receiverId ${_auth.currentUser?.uid}: $e');
      rethrow;
    }
  }

  // Fetch a request by ID
  Future<RequestModel> getRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection('requests').doc(requestId).get();
      if (!doc.exists) throw Exception('Request not found');
      RequestModel request = RequestModel.fromFirestore(doc);
      // Fetch sender and receiver user data
      request.senderUser = await getUser(request.senderId);
      request.targetUser = await getUser(request.receiverId);
      return request;
    } catch (e) {
      debugPrint('Error fetching request $requestId: $e');
      rethrow;
    }
  }

  // Update a request (generic method for status updates, etc.)
  Future<void> updateRequest(String requestId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection('requests').doc(requestId).update(updates);
      debugPrint('Request $requestId updated successfully');
    } catch (e) {
      debugPrint('Error updating request $requestId: $e');
      rethrow;
    }
  }

  // Create a review after session completion
  Future<void> createReview({
    required String requestId,
    required String reviewerId,
    required String reviewedUserId,
    required double rating,
    required String comment,
  }) async {
    try {
      await _firestore.collection('reviews').add({
        'requestId': requestId,
        'reviewerId': reviewerId,
        'reviewedUserId': reviewedUserId,
        'rating': rating,
        'comment': comment,
        'createdAt': DateTime.now().toIso8601String(),
      });
      debugPrint('Review created for request $requestId by reviewer $reviewerId');

      // Update the reviewed user's rating
      await _updateUserRating(reviewedUserId);
    } catch (e) {
      debugPrint('Error creating review for request $requestId: $e');
      rethrow;
    }
  }

  // Update a user's rating based on their reviews
  Future<void> _updateUserRating(String userId) async {
    try {
      QuerySnapshot reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('reviewedUserId', isEqualTo: userId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        debugPrint('No reviews found for user $userId, setting rating to 0');
        await _firestore.collection('users').doc(userId).update({'rating': 0.0});
        await syncUserToPublicProfile(userId);
        return;
      }

      double totalRating = 0.0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc['rating'] as num).toDouble();
      }
      double averageRating = totalRating / reviewsSnapshot.docs.length;

      await _firestore.collection('users').doc(userId).update({'rating': averageRating});
      await syncUserToPublicProfile(userId);
      debugPrint('Updated rating for user $userId to $averageRating');
    } catch (e) {
      debugPrint('Error updating rating for user $userId: $e');
      rethrow;
    }
  }

  // Profile

  // Update user profile
  Future<void> updateUserProfile(
      String userId, {
        String? fullName,
        String? email,
        String? location,
        List<String>? skillsCanTeach,
        List<String>? skillsWantToLearn,
      }) async {
    try {
      Map<String, dynamic> updates = {};
      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (location != null) updates['location'] = location;
      if (skillsCanTeach != null) updates['skillsCanTeach'] = skillsCanTeach;
      if (skillsWantToLearn != null) updates['skillsWantToLearn'] = skillsWantToLearn;

      await _firestore.collection('users').doc(userId).update(updates);

      // Update email in Firebase Auth if changed
      if (email != null) {
        await _auth.currentUser!.updateEmail(email);
      }
      await syncUserToPublicProfile(userId);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Re-authenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update the password
      await user.updatePassword(newPassword);
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteUserAccount(String userId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.uid != userId) {
        throw Exception('No user signed in or user ID mismatch');
      }

      // Start a Firestore batch to ensure atomic operations
      WriteBatch batch = _firestore.batch();

      // 1. Delete user document from 'users' collection
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      batch.delete(userRef);
      debugPrint('Scheduled deletion of users/$userId');

      // 2. Delete user document from 'public_profiles' collection
      DocumentReference publicProfileRef = _firestore.collection('public_profiles').doc(userId);
      batch.delete(publicProfileRef);
      debugPrint('Scheduled deletion of public_profiles/$userId');

      // 3. Delete related requests (sent and received)
      QuerySnapshot sentRequests = await _firestore
          .collection('requests')
          .where('senderId', isEqualTo: userId)
          .get();
      for (var doc in sentRequests.docs) {
        batch.delete(doc.reference);
        debugPrint('Scheduled deletion of request/${doc.id} (sender)');
      }

      QuerySnapshot receivedRequests = await _firestore
          .collection('requests')
          .where('receiverId', isEqualTo: userId)
          .get();
      for (var doc in receivedRequests.docs) {
        batch.delete(doc.reference);
        debugPrint('Scheduled deletion of request/${doc.id} (receiver)');
      }

      // 4. Delete conversations involving the user
      QuerySnapshot conversations = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .get();
      for (var doc in conversations.docs) {
        // Delete messages subcollection
        QuerySnapshot messages = await _firestore
            .collection('conversations')
            .doc(doc.id)
            .collection('messages')
            .get();
        for (var msg in messages.docs) {
          batch.delete(msg.reference);
          debugPrint('Scheduled deletion of conversations/${doc.id}/messages/${msg.id}');
        }
        // Delete conversation document
        batch.delete(doc.reference);
        debugPrint('Scheduled deletion of conversations/${doc.id}');
      }

      // 5. Delete reviews given or received by the user
      QuerySnapshot reviewsGiven = await _firestore
          .collection('reviews')
          .where('reviewerId', isEqualTo: userId)
          .get();
      for (var doc in reviewsGiven.docs) {
        batch.delete(doc.reference);
        debugPrint('Scheduled deletion of reviews/${doc.id} (given)');
      }

      QuerySnapshot reviewsReceived = await _firestore
          .collection('reviews')
          .where('reviewedUserId', isEqualTo: userId)
          .get();
      for (var doc in reviewsReceived.docs) {
        batch.delete(doc.reference);
        debugPrint('Scheduled deletion of reviews/${doc.id} (received)');
      }

      // 6. Delete contact messages sent by the user
      QuerySnapshot contactMessages = await _firestore
          .collection('contact_messages')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in contactMessages.docs) {
        batch.delete(doc.reference);
        debugPrint('Scheduled deletion of contact_messages/${doc.id}');
      }

      // Commit the batch to Firestore
      await batch.commit();
      debugPrint('All Firestore deletions completed for userId: $userId');

      // 7. Delete user from Firebase Authentication
      await user.delete();
      debugPrint('Firebase Authentication user deleted: $userId');
    } catch (e) {
      debugPrint('Error deleting user account for userId $userId: $e');
      rethrow;
    }
  }

  // Get user availability
  Future<List<DateTime>> getUserAvailability(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists || doc['availability'] == null) {
        debugPrint('No availability data found for user $userId');
        return [];
      }

      List<dynamic> availabilityData = doc['availability'] as List<dynamic>;
      debugPrint('Fetched availability for user $userId: $availabilityData');
      return availabilityData
          .map((dateStr) => DateTime.parse(dateStr as String))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user availability for user $userId: $e');
      rethrow;
    }
  }

  // Update user availability
  Future<void> updateUserAvailability(String userId, List<DateTime> availability) async {
    try {
      // Convert List<DateTime> to List<String> in YYYY-MM-DD format for Firestore
      List<String> availabilityStrings = availability.map((date) => date.toIso8601String().split('T')[0]).toList();
      await _firestore.collection('users').doc(userId).update({
        'availability': availabilityStrings,
      });
      await syncUserToPublicProfile(userId);
      debugPrint('Updated availability for user $userId: $availabilityStrings');
    } catch (e) {
      debugPrint('Error updating user availability for user $userId: $e');
      rethrow;
    }
  }

  // Send contact message
  Future<void> sendContactMessage({
    required String userId,
    required String message,
  }) async {
    try {
      await _firestore.collection('contact_messages').add({
        'userId': userId,
        'message': message,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error sending contact message: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}