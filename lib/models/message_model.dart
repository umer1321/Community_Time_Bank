import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String content;
  final String senderId;
  final Timestamp timestamp;

  MessageModel({
    required this.id,
    required this.content,
    required this.senderId,
    required this.timestamp,
  });

  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    return MessageModel(
      id: doc.id,
      content: doc['content'] ?? '',
      senderId: doc['senderId'] ?? '',
      timestamp: doc['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'senderId': senderId,
      'timestamp': timestamp,
    };
  }
}