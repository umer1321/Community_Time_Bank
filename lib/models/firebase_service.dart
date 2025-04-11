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
      print('Error sending message: $e');
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

  /// Rest of the FirebaseService methods remain unchanged

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

  // Fetch recommended users
  Future<List<UserModel>> getRecommendedUsers(String currentUserId, List<String> skillsWantToLearn) async {
    try {
      debugPrint('Fetching recommended users from public_profiles for user ID: $currentUserId');
      QuerySnapshot querySnapshot = await _firestore.collection('public_profiles').get();
      List<UserModel> allUsers = [];

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
}