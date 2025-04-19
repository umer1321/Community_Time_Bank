import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import '../../models/navigation_service.dart';
import '../../utils/constants.dart';
import '../../utils/routes.dart';

import '../../models/firebase_service.dart';
import '../../models/user_model.dart';
import '../widgets/UserCard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _currentUser;
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  bool _isLoadingUsers = true;
  int _selectedIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _skillCategoryFilter;
  String? _locationFilter;
  double? _ratingFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterUsers();
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user signed in, redirecting to login');
        _safeNavigate(Routes.login);
        return;
      }

      debugPrint('Fetching user data for UID: ${user.uid}');
      _currentUser = await _firebaseService.getUser(user.uid);
      if (_currentUser == null) {
        debugPrint('User data not found in Firestore, signing out');
        await FirebaseAuth.instance.signOut();
        _safeNavigate(Routes.login);
        return;
      }

      await _firebaseService.updateUserWithMissingFields(user.uid);
      _currentUser = await _firebaseService.getUser(user.uid);

      debugPrint('User data fetched: ${_currentUser!.toMap()}');
      debugPrint('hasSeenWelcomePopup: ${_currentUser!.hasSeenWelcomePopup}');
      if (!_currentUser!.hasSeenWelcomePopup && mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          debugPrint('Showing welcome popup');
          _showWelcomePopup();
        });
      }

      await _loadAllUsers();
    } catch (e) {
      debugPrint('Error loading current user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user data. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      if (_currentUser == null) return;

      debugPrint('Loading recommended users for UID: ${_currentUser!.uid}');
      List<UserModel> allUsers = await _firebaseService.getRecommendedUsers(
        _currentUser!.uid,
        _currentUser!.skillsWantToLearn,
      );
      setState(() {
        _allUsers = allUsers;
        _filteredUsers = allUsers;
        _isLoadingUsers = false;
      });
      _filterUsers();
      debugPrint('Loaded ${_allUsers.length} recommended users: ${_allUsers.map((u) => u.fullName).toList()}');
    } catch (e) {
      debugPrint('Error loading users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load recommended users. Please try again.')),
      );
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        bool matchesSearch = _searchQuery.isEmpty ||
            user.fullName.toLowerCase().contains(_searchQuery) ||
            user.role.toLowerCase().contains(_searchQuery) ||
            user.skillsCanTeach.any((skill) => skill.toLowerCase().contains(_searchQuery));

        bool matchesSkillCategory = _skillCategoryFilter == null ||
            user.skillsCanTeach.contains(_skillCategoryFilter);

        bool matchesLocation = _locationFilter == null ||
            user.availability.any((date) =>
                date.toIso8601String().split('T')[0].contains(_locationFilter!));

        bool matchesRating = _ratingFilter == null || user.rating >= _ratingFilter!;

        return matchesSearch && matchesSkillCategory && matchesLocation && matchesRating;
      }).toList();
      debugPrint('Filtered users: ${_filteredUsers.length}');
    });
  }

  void _showWelcomePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (_currentUser != null) {
                    try {
                      debugPrint('Updating hasSeenWelcomePopup to true for UID: ${_currentUser!.uid}');
                      await _firebaseService.updateWelcomePopupFlag(_currentUser!.uid, true);
                      setState(() {
                        _currentUser = _currentUser!.copyWith(hasSeenWelcomePopup: true);
                      });
                    } catch (e) {
                      debugPrint('Error updating welcome popup flag: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update welcome status')),
                      );
                    }
                  }
                },
              ),
            ),
            const Text('Welcome to', style: TextStyle(fontSize: 16)),
            const Text(
              'Community Time Bank',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We gift you one time credit in your account as a welcome gift.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'The time credits will be in ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                _safeNavigate(Routes.profile, arguments: _currentUser);
              },
              child: const Text(
                'profile-time credits summary',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.primaryRed,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 30,
              backgroundImage: _currentUser!.profilePictureUrl.isNotEmpty
                  ? NetworkImage(_currentUser!.profilePictureUrl)
                  : const AssetImage('assets/images/default_profile.png'),
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint('Error loading profile picture: $exception');
              },
            ),
            const SizedBox(height: 8),
            Text(
              _currentUser?.fullName ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _safeNavigate(Routes.profile, arguments: _currentUser);
              },
              child: const Text('View Profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        _safeNavigate(Routes.requests);
        break;
      case 2:
        _safeNavigate(Routes.messageList);
        break;
      case 3:
        _safeNavigate(Routes.profile, arguments: _currentUser);
        break;
    }
  }

  void _safeNavigate(String route, {Object? arguments}) {
    if (!mounted) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (arguments != null) {
          NavigationService().navigateTo(route, arguments: arguments);
        } else {
          NavigationService().navigateTo(route);
        }
      } catch (e) {
        debugPrint('Navigation error: $e');
      }
    });
  }

  void _navigateBackToRoleSelection() {
    if (_currentUser == null || _currentUser!.role.isEmpty) {
      debugPrint('Cannot navigate back: Current user or role is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User role not found. Please log in again.')),
      );
      return;
    }
    _safeNavigate(Routes.roleSelection, arguments: _currentUser!.role);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _skillCategoryFilter = null;
      _locationFilter = null;
      _ratingFilter = null;
      _filterUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSearchActive = _searchQuery.isNotEmpty ||
        _skillCategoryFilter != null ||
        _locationFilter != null ||
        _ratingFilter != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.primaryBlue),
          onPressed: _navigateBackToRoleSelection,
        ),
        title: Text(
          AppConstants.appName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryBlue,
          ),
        ),
        backgroundColor: AppConstants.cardBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(AppConstants.notificationIcon, color: AppConstants.primaryBlue),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryBlue))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Your Next Skill!!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textBlack,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for a skill...',
                        prefixIcon: const Icon(
                          AppConstants.searchIcon,
                          color: AppConstants.textGray,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'Skill Category',
                          _skillCategoryFilter,
                          ['Yoga', 'Coding', 'Cooking'],
                              (value) {
                            setState(() {
                              _skillCategoryFilter = value;
                              _filterUsers();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Available Date',
                          _locationFilter,
                          ['2025-04-05', '2025-04-06'],
                              (value) {
                            setState(() {
                              _locationFilter = value;
                              _filterUsers();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Rating',
                          _ratingFilter?.toString(),
                          ['4.0', '3.0', '2.0'],
                              (value) {
                            setState(() {
                              _ratingFilter = value != null ? double.parse(value) : null;
                              _filterUsers();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                isSearchActive ? 'Search Result' : 'Recommended for You',
                style: AppConstants.cardTitleStyle,
              ),
            ),
            _isLoadingUsers
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryBlue))
                : _filteredUsers.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No recommended users available. Try inviting more friends to join!',
                style: AppConstants.cardSubtitleStyle,
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredUsers.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return UserCard(
                  user: user,
                  isSearchResult: isSearchActive,
                  onViewProfile: () async {
                    debugPrint('Checking user existence for UID: ${user.uid}');
                    final userExists = await _firebaseService.getUser(user.uid);
                    if (userExists != null && mounted) {
                      debugPrint('Navigating to skill detail for user: ${user.fullName}');
                      _safeNavigate(Routes.skillDetail, arguments: {'user': user});
                    } else {
                      debugPrint('User not found for UID: ${user.uid}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not found')),
                      );
                    }
                  },
                  onRequestSkill: isSearchActive
                      ? () async {
                    debugPrint('Request Skill for user: ${user.fullName}');
                    final currentUserId = _firebaseService.getCurrentUserId();
                    if (currentUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in to request a skill')),
                      );
                      return;
                    }
                    try {
                      final userExists = await _firebaseService.getUser(user.uid);
                      if (userExists == null) {
                        debugPrint('Target user not found: ${user.uid}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User not found')),
                        );
                        return;
                      }
                      String requestId = await _firebaseService.createSkillRequest(
                        requesterUid: currentUserId,
                        targetUid: user.uid,
                        skillOffered: '',
                        skillWanted: user.skillsCanTeach.isNotEmpty ? user.skillsCanTeach[0] : '',
                        skillRequested: user.skillsCanTeach.isNotEmpty ? user.skillsCanTeach[0] : '',
                        sessionDate: '2025-04-15',
                        sessionTime: '10:00 AM',
                        additionalNotes: 'Interested in learning ${user.skillsCanTeach.isNotEmpty ? user.skillsCanTeach[0] : 'a skill'}',
                        sessionReminder: true,
                      );
                      String conversationId = await _firebaseService.createConversation(
                        currentUserId,
                        user.uid,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Skill request sent to ${user.fullName}')),
                      );
                      _safeNavigate(Routes.skillDetail, arguments: {'user': user});
                    } catch (e) {
                      debugPrint('Error requesting skill: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send skill request: $e')),
                      );
                    }
                  }
                      : () {},
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(AppConstants.homeIcon), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(AppConstants.requestsIcon), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(AppConstants.messagesIcon), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(AppConstants.profileIcon), label: 'Profile'),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: AppConstants.primaryBlue,
        unselectedItemColor: AppConstants.textGray,
        backgroundColor: AppConstants.cardBackground,
        elevation: 8,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildFilterChip(
      String label,
      String? selectedValue,
      List<String> options,
      ValueChanged<String?> onChanged,
      ) {
    return GestureDetector(
      onTap: () async {
        final String? result = await showModalBottomSheet<String>(
          context: context,
          builder: (context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Clear Filter'),
                  onTap: () => Navigator.pop(context, null),
                ),
                ...options.map((option) => ListTile(
                  title: Text(option),
                  onTap: () => Navigator.pop(context, option),
                )),
              ],
            );
          },
        );
        onChanged(result);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedValue ?? label,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

extension on UserModel {
  UserModel copyWith({bool? hasSeenWelcomePopup}) {
    return UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      skillsCanTeach: skillsCanTeach,
      skillsWantToLearn: skillsWantToLearn,
      role: role,
      availability: availability,
      timeCredits: timeCredits,
      hasSeenWelcomePopup: hasSeenWelcomePopup ?? this.hasSeenWelcomePopup,
      profilePictureUrl: profilePictureUrl,
      rating: rating,
      location: location,
      bio: bio,
    );
  }
}