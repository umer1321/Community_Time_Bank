import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class ConversationModel {
  final String id;
  final String lastMessage;
  final Timestamp lastMessageTime;
  final UserModel otherUser;

  ConversationModel({
    required this.id,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.otherUser,
  });

  factory ConversationModel.fromDocument(DocumentSnapshot doc, UserModel otherUser) {
    return ConversationModel(
      id: doc.id,
      lastMessage: doc['lastMessage'] ?? '',
      lastMessageTime: doc['lastMessageTime'] ?? Timestamp.now(),
      otherUser: otherUser,
    );
  }
}