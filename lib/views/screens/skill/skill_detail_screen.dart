// lib/views/screens/skill/skill_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:community_time_bank/models/user_model.dart';
import 'package:community_time_bank/utils/routes.dart';

class SkillDetailScreen extends StatelessWidget {
  final UserModel user; // Add the user parameter

  const SkillDetailScreen({super.key, required this.user}); // Update constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Skill Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: user.profilePictureUrl.isNotEmpty
                      ? NetworkImage(user.profilePictureUrl)
                      : const NetworkImage('https://via.placeholder.com/150'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.location ?? 'Not specified',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.red),
                  onPressed: () {
                    // Implement favorite functionality
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Skills I Can Teach',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: user.skillsCanTeach.isNotEmpty
                  ? user.skillsCanTeach
                  .map(
                    (skill) => Chip(
                  label: Text(skill),
                  backgroundColor: Colors.blue[100],
                  labelStyle: const TextStyle(color: Colors.blue),
                ),
              )
                  .toList()
                  : [
                const Text(
                  'No skills listed.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Skills I Want to Learn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: user.skillsWantToLearn.isNotEmpty
                  ? user.skillsWantToLearn
                  .map(
                    (skill) => Chip(
                  label: Text(skill),
                  backgroundColor: Colors.green[100],
                  labelStyle: const TextStyle(color: Colors.green),
                ),
              )
                  .toList()
                  : [
                const Text(
                  'No skills listed.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < user.rating.floor()
                        ? Icons.star
                        : (index < user.rating ? Icons.star_half : Icons.star_border),
                    size: 16,
                    color: Colors.amber,
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  user.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.requestSkillExchange,
                    arguments: {
                      'targetUser': user,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Request Skill Exchange',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}