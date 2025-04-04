// lib/views/widgets/user_card.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class UserCard extends StatelessWidget {
  final String name;
  final String role;
  final double rating;
  final String? imageUrl;
  final VoidCallback onViewProfile;
  final VoidCallback onRequestSkill;
  final bool isSearchResult;

  const UserCard({
    super.key,
    required this.name,
    required this.role,
    required this.rating,
    this.imageUrl,
    required this.onViewProfile,
    required this.onRequestSkill,
    this.isSearchResult = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearchResult) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                    ? NetworkImage(imageUrl!)
                    : const NetworkImage('https://via.placeholder.com/150'),
                backgroundColor: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.floor() ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      })..addAll([
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onRequestSkill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Request Skill'),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Stack(
          children: [
            // Background image
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                image: const DecorationImage(
                  image: NetworkImage('https://via.placeholder.com/300'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Profile picture
            Positioned(
              top: 80,
              left: 16,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                    ? NetworkImage(imageUrl!)
                    : const NetworkImage('https://via.placeholder.com/150'),
                backgroundColor: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
            // Card content
            Padding(
              padding: const EdgeInsets.only(top: 100, left: 100, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating.floor() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    })..addAll([
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onViewProfile,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Profile',
                            style: TextStyle(
                              color: AppConstants.primaryBlue,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: AppConstants.primaryBlue,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}