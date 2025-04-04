// lib/views/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../utils/routes.dart';
import '../widgets/UserCard.dart';

import '../../models/firebase_service.dart';
import '../../models/user_model.dart';

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
  int _selectedIndex = 0; // For bottom navigation bar

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _skillCategoryFilter;
  String? _locationFilter;
  double? _ratingFilter;
  String? _availabilityFilter;

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
        Navigator.pushReplacementNamed(context, Routes.login);
        return;
      }

      debugPrint('Fetching user data for UID: ${user.uid}');
      _currentUser = await _firebaseService.getUser(user.uid);
      if (_currentUser == null) {
        debugPrint('User data not found in Firestore, signing out');
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, Routes.login);
        return;
      }

      debugPrint('User data fetched: ${_currentUser!.toMap()}');
      debugPrint('hasSeenWelcomePopup: ${_currentUser!.hasSeenWelcomePopup}');
      if (!_currentUser!.hasSeenWelcomePopup) {
        debugPrint('User has not seen welcome popup, showing popup');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint('Inside addPostFrameCallback, calling _showWelcomePopup');
            _showWelcomePopup();
          });
        } else {
          debugPrint('Widget not mounted, cannot show welcome popup');
        }
      } else {
        debugPrint('User has already seen welcome popup, skipping');
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
      debugPrint('Loaded ${_allUsers.length} recommended users');
    } catch (e) {
      debugPrint('Error loading users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load users')),
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
            user.availability.keys.any((date) => date.contains(_locationFilter!));

        bool matchesRating = _ratingFilter == null || user.rating >= _ratingFilter!;

        bool matchesAvailability = _availabilityFilter == null ||
            user.availability.values.any((times) => times.contains(_availabilityFilter));

        return matchesSearch &&
            matchesSkillCategory &&
            matchesLocation &&
            matchesRating &&
            matchesAvailability;
      }).toList();
      debugPrint('Filtered users: ${_filteredUsers.length}');
    });
  }

  void _showWelcomePopup() {
    debugPrint('Showing welcome popup');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  debugPrint('Welcome popup dismissed');
                  Navigator.of(context).pop();
                  if (_currentUser != null) {
                    try {
                      debugPrint('Updating hasSeenWelcomePopup to true for UID: ${_currentUser!.uid}');
                      await _firebaseService.updateWelcomePopupFlag(
                        _currentUser!.uid,
                        true,
                      );
                      setState(() {
                        _currentUser = UserModel(
                          uid: _currentUser!.uid,
                          fullName: _currentUser!.fullName,
                          email: _currentUser!.email,
                          skillsCanTeach: _currentUser!.skillsCanTeach,
                          skillsWantToLearn: _currentUser!.skillsWantToLearn,
                          role: _currentUser!.role,
                          availability: _currentUser!.availability,
                          timeCredits: _currentUser!.timeCredits,
                          hasSeenWelcomePopup: true,
                          profilePictureUrl: _currentUser!.profilePictureUrl,
                          rating: _currentUser!.rating,
                          location: _currentUser!.location,
                          bio: _currentUser!.bio,
                        );
                      });
                      debugPrint('hasSeenWelcomePopup updated successfully');
                    } catch (e) {
                      debugPrint('Error updating welcome popup flag: $e');
                      String errorMessage = 'Failed to update welcome status';
                      if (e is FirebaseException) {
                        if (e.code == 'permission-denied') {
                          errorMessage = 'Permission denied. Please sign in again.';
                        } else if (e.code == 'not-found') {
                          errorMessage = 'User data not found. Please sign in again.';
                        }
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage)),
                      );
                    }
                  }
                },
              ),
            ),
            const Text(
              'Welcome to',
              style: TextStyle(fontSize: 16),
            ),
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
                Navigator.pushNamed(
                  context,
                  Routes.profile,
                  arguments: _currentUser,
                );
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
              backgroundImage: _currentUser?.profilePictureUrl != null && _currentUser!.profilePictureUrl.isNotEmpty
                  ? NetworkImage(_currentUser!.profilePictureUrl) as ImageProvider
                  : const AssetImage('assets/images/default_profile.png'),
            ),
            const SizedBox(height: 8),
            Text(
              _currentUser?.fullName ?? 'User',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                foregroundColor: AppConstants.textWhite,
                minimumSize: const Size(120, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                debugPrint('View Profile button pressed in welcome popup');
                Navigator.of(context).pop();
                Navigator.pushNamed(
                  context,
                  Routes.profile,
                  arguments: _currentUser,
                );
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
      // Already on Home
        break;
      case 1:
        Navigator.pushNamed(context, Routes.requestSkill);
        break;
      case 2:
        Navigator.pushNamed(context, Routes.messageList);
        break;
      case 3:
        Navigator.pushNamed(context, Routes.profile, arguments: _currentUser);
        break;
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _skillCategoryFilter = null;
      _locationFilter = null;
      _ratingFilter = null;
      _availabilityFilter = null;
      _filterUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSearchActive = _searchQuery.isNotEmpty ||
        _skillCategoryFilter != null ||
        _locationFilter != null ||
        _ratingFilter != null ||
        _availabilityFilter != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.appName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryBlue,
          ),
        ),
        backgroundColor: AppConstants.cardBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              AppConstants.notificationIcon,
              color: AppConstants.primaryBlue,
            ),
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
                          'Location',
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
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Availability',
                          _availabilityFilter,
                          ['10:00 AM', '11:00 AM'],
                              (value) {
                            setState(() {
                              _availabilityFilter = value;
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
                'No users found.',
                style: AppConstants.cardSubtitleStyle,
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredUsers.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return isSearchActive
                    ? UserCard(
                  name: user.fullName,
                  role: user.role,
                  rating: user.rating,
                  imageUrl: user.profilePictureUrl,
                  onViewProfile: () {
                    debugPrint('Navigating to profile for user: ${user.fullName}');
                    Navigator.pushNamed(
                      context,
                      Routes.profile,
                      arguments: user,
                    );
                  },
                  onRequestSkill: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Skill request sent to ${user.fullName}')),
                    );
                  },
                  isSearchResult: true,
                )
                    : UserCard(
                  name: user.fullName,
                  role: user.role,
                  rating: user.rating,
                  imageUrl: user.profilePictureUrl,
                  onViewProfile: () {
                    debugPrint('Navigating to profile for user: ${user.fullName}');
                    Navigator.pushNamed(
                      context,
                      Routes.profile,
                      arguments: user,
                    );
                  },
                  onRequestSkill: () {},
                  isSearchResult: false,
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(AppConstants.homeIcon),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppConstants.requestsIcon),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppConstants.messagesIcon),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppConstants.profileIcon),
            label: 'Profile',
          ),
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
              const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}