// lib/views/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import '../../../models/firebase_service.dart';
import '../../../models/user_model.dart';
import '../../../utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/routes.dart';

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
  String? _selectedSkillOffered; // To store the selected skill offered
  String? _selectedSkillWanted;  // To store the selected skill wanted

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.red, size: 22),
            onPressed: () {
              // Implement bookmark functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.blue, size: 22),
            onPressed: () {
              // Implement more options
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _user!.profilePictureUrl.isNotEmpty
                      ? NetworkImage(_user!.profilePictureUrl)
                      : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                  onBackgroundImageError: (exception, stackTrace) {
                    debugPrint('Error loading profile picture: $exception');
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _user!.location ?? 'Curitiba',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Skills Offered
            const Text(
              'Skill Offered',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_user!.skillsCanTeach.isEmpty
                  ? ['UI Designer', 'Graphics']
                  : _user!.skillsCanTeach).map((skill) {
                final isSelected = _selectedSkillOffered == skill;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSkillOffered = skill;
                      _selectedSkillWanted = null; // Reset the other selection
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[900] : Colors.blue[700],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Skills Requested
            const Text(
              'Skill Requested',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_user!.skillsWantToLearn.isEmpty
                  ? ['Next.js', 'Java']
                  : _user!.skillsWantToLearn).map((skill) {
                final isSelected = _selectedSkillWanted == skill;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSkillWanted = skill;
                      _selectedSkillOffered = null; // Reset the other selection
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[900] : const Color(0xFF3F3D56),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Bio / Experience
            const Text(
              'Bio / Experience',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _user!.bio ?? 'Lorem ipsum dolor sit amet consectetur. Elementum hendrerit enim id cursus. Integer egestas est adipiscing augue. Mi felis lectus metus accumsan volutpat.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rating',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                InkWell(
                  onTap: () {
                    // View all ratings
                  },
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (_user!.rating?.floor() ?? 4) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_user!.rating ?? 4}/5',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Request Skill Button
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedSkillOffered != null || _selectedSkillWanted != null)
                      ? () {
                    // Navigate to RequestSkillExchangeScreen with the target user and selected skills
                    Navigator.pushNamed(
                      context,
                      Routes.requestSkillExchange,
                      arguments: {
                        'targetUser': _user,
                        'preSelectedSkillOffered': _selectedSkillOffered,
                        'preSelectedSkillWanted': _selectedSkillWanted,
                      },
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Request This Skill',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}