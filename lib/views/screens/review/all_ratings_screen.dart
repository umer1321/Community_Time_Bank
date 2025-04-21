import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:community_time_bank/models/review_model.dart';
import 'package:community_time_bank/models/firebase_service.dart';
import 'package:community_time_bank/views/screens/review/full_rating_screen.dart';

class AllRatingsScreen extends StatefulWidget {
  final String userId;

  const AllRatingsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<AllRatingsScreen> createState() => _AllRatingsScreenState();
}

class _AllRatingsScreenState extends State<AllRatingsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('reviewedUserId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();

      final reviews = snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
      for (var review in reviews) {
        review.reviewer = await _firebaseService.getUserById(review.reviewerId);
      }

      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching reviews: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Ratings'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _reviews.isEmpty
          ? const Center(child: Text('No reviews yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(review.reviewer!.profilePictureUrl),
              ),
              title: Text(review.reviewer!.fullName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      review.rating.toInt(),
                          (i) => const Icon(Icons.star, color: Colors.amber, size: 16),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(review.comment.isNotEmpty ? review.comment : 'No comment'),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullRatingScreen(review: review),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}