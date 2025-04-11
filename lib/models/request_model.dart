// lib/models/request_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class RequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String skillOffered;
  final String skillWanted;
  final String skillRequested;
  final String sessionDate;
  final String sessionTime;
  final String additionalNotes;
  final String status;
  final String createdAt;
  final String updatedAt;
  final bool sessionReminder;
  UserModel? senderUser; // Added to store sender user data
  UserModel? targetUser; // Added to store target user data

  RequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.skillOffered,
    required this.skillWanted,
    required this.skillRequested,
    required this.sessionDate,
    required this.sessionTime,
    required this.additionalNotes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.sessionReminder,
    this.senderUser,
    this.targetUser,
  });

  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequestModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      skillOffered: data['skillOffered'] ?? '',
      skillWanted: data['skillWanted'] ?? '',
      skillRequested: data['skillRequested'] ?? '',
      sessionDate: data['sessionDate'] ?? '',
      sessionTime: data['sessionTime'] ?? '',
      additionalNotes: data['additionalNotes'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? '',
      updatedAt: data['updatedAt'] ?? '',
      sessionReminder: data['sessionReminder'] ?? false,
    );
  }
}