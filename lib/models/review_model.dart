import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class ReviewModel {
  final String id;
  final String requestId;
  final String reviewerId;
  final String reviewedUserId;
  final double rating;
  final String comment;
  final String createdAt;
  UserModel? reviewer;

  ReviewModel({
    required this.id,
    required this.requestId,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.reviewer,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewedUserId: data['reviewedUserId'] ?? '',
      rating: (data['rating'] as num).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] ?? '',
    );
  }
}