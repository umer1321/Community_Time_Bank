// lib/views/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../../../models/firebase_service.dart';
import '../../../models/user_model.dart';
import '../../../utils/constants.dart';

import 'package:firebase_auth/firebase_auth.dart';


class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      debugPrint('Fetching user data for UID: ${widget.user.uid}');
      final fetchedUser = await _firebaseService.getUser(widget.user.uid);
      if (fetchedUser == null) {
        debugPrint('User data not found for UID: ${widget.user.uid}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found')),
        );
        Navigator.pop(context);
        return;
      }
      setState(() {
        _user = fetchedUser;
        _isLoading = false;
      });
      debugPrint('User data fetched: ${_user!.toMap()}');
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user data')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnProfile = currentUser != null && currentUser.uid == widget.user.uid;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppConstants.primaryBlue)),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.primaryBlue),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: AppConstants.cardBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _user!.profilePictureUrl.isNotEmpty
                        ? NetworkImage(_user!.profilePictureUrl)
                        : const NetworkImage('https://via.placeholder.com/150'),
                    backgroundColor: Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user!.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _user!.location ?? 'Not specified',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share, color: AppConstants.primaryBlue),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share feature coming soon!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: AppConstants.primaryRed),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Favorite feature coming soon!')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Skills Offered
              const Text(
                'Skill Offered',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _user!.skillsCanTeach.map((skill) {
                  return Chip(
                    label: Text(skill),
                    backgroundColor: AppConstants.primaryBlue,
                    labelStyle: const TextStyle(color: Colors.white),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Skills Requested
              const Text(
                'Skill Requested',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _user!.skillsWantToLearn.map((skill) {
                  return Chip(
                    label: Text(skill),
                    backgroundColor: AppConstants.primaryBlue,
                    labelStyle: const TextStyle(color: Colors.white),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Bio/Experience
              const Text(
                'Bio / Experience',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _user!.bio ??
                      'Lorem ipsum dolor sit amet consectetur. Elementum hendrerit enim id cursus. Integer egestas est adipiscing augue. Mi felis lectus metus accumsan volutpat.',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 16),

              // Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < _user!.rating.floor() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_user!.rating.toStringAsFixed(1)}/5',
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('View all reviews feature coming soon!')),
                      );
                    },
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        color: AppConstants.primaryBlue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Request This Skill Button (only for other users' profiles)
              if (!isOwnProfile)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Skill request sent to ${_user!.fullName}')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Request This Skill',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}