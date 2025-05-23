import 'package:flutter/material.dart';
import '../../../models/firebase_service.dart';
import '../../../models/user_model.dart';
import '../../../utils/routes.dart';
import '../../widgets/UserCard.dart';


class SearchSkillsScreen extends StatefulWidget {
  const SearchSkillsScreen({super.key});

  @override
  State<SearchSkillsScreen> createState() => _SearchSkillsScreenState();
}

class _SearchSkillsScreenState extends State<SearchSkillsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String? _currentUserId;
  String? _selectedCategory;
  String? _selectedLocation;
  String? _selectedRating;
  bool _showAvailableOnly = false;

  @override
  void initState() {
    super.initState();
    debugPrint('SearchSkillsScreen initialized');
    _fetchCurrentUserId();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _fetchCurrentUserId() async {
    _currentUserId = _firebaseService.getCurrentUserId();
    if (_currentUserId == null) {
      debugPrint('Current user ID is null, redirecting to login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
      return;
    }
    await _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      debugPrint('Fetching all users...');
      List<UserModel> users = await _firebaseService.getAllUsers();
      debugPrint('Users fetched: ${users.length}');
      setState(() {
        _users = users.where((user) => user.uid != _currentUserId).toList();
        _filteredUsers = _users;
        _isLoading = false;
      });
      debugPrint('Fetched users: ${_users.length}, Filtered users: ${_filteredUsers.length}');
      debugPrint('Users: ${_users.map((u) => u.fullName).toList()}');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error fetching users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load users. Please try again.')),
      );
    }
  }

  void _filterUsers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        bool matchesQuery = user.fullName.toLowerCase().contains(query) ||
            user.skillsCanTeach.any((skill) => skill.toLowerCase().contains(query)) ||
            user.skillsWantToLearn.any((skill) => skill.toLowerCase().contains(query));

        bool matchesCategory = _selectedCategory == null ||
            user.skillsCanTeach.contains(_selectedCategory) ||
            user.skillsWantToLearn.contains(_selectedCategory);

        bool matchesLocation = _selectedLocation == null || user.location == _selectedLocation;

        bool matchesRating = _selectedRating == null ||
            (_selectedRating == '4+' && user.rating >= 4) ||
            (_selectedRating == '3+' && user.rating >= 3) ||
            (_selectedRating == '2+' && user.rating >= 2);

        bool matchesAvailability = !_showAvailableOnly; // Placeholder, update if needed

        return matchesQuery && matchesCategory && matchesLocation && matchesRating && matchesAvailability;
      }).toList();
      debugPrint('Filtered users: ${_filteredUsers.length}');
    });
  }

  Future<void> _requestSkill(UserModel targetUser) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to request a skill')),
      );
      return;
    }

    try {
      String requestId = await _firebaseService.createSkillRequest(
        requesterUid: _currentUserId!,
        targetUid: targetUser.uid,
        skillOffered: '',
        skillWanted: targetUser.skillsCanTeach.isNotEmpty ? targetUser.skillsCanTeach[0] : '',
        skillRequested: targetUser.skillsCanTeach.isNotEmpty ? targetUser.skillsCanTeach[0] : '',
        sessionDate: '2025-04-15',
        sessionTime: '10:00 AM',
        additionalNotes: 'Interested in learning ${targetUser.skillsCanTeach.isNotEmpty ? targetUser.skillsCanTeach[0] : 'a skill'}',
        sessionReminder: true,
      );

      String conversationId = await _firebaseService.createConversation(
        _currentUserId!,
        targetUser.uid,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Skill request sent to ${targetUser.fullName}')),
      );

      Navigator.pushNamed(
        context,
        Routes.skillDetail,
        arguments: {'user': targetUser},
      );
      debugPrint('Navigating to skillDetail for user: ${targetUser.fullName}');
    } catch (e) {
      debugPrint('Error requesting skill: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send skill request: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    debugPrint('SearchSkillsScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building SearchSkillsScreen');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () {
            debugPrint('Back button pressed');
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Community Time Bank',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              debugPrint('Notifications button pressed');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find Your Next Skill!!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or skill...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterUsers();
                    debugPrint('Search field cleared');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
              onTap: () {
                debugPrint('Search field tapped');
              },
              onSubmitted: (value) {
                debugPrint('Search submitted: $value');
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  hint: const Text('Skill Category'),
                  value: _selectedCategory,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    const DropdownMenuItem(value: 'Coding', child: Text('Coding')),
                    const DropdownMenuItem(value: 'Cooking', child: Text('Cooking')),
                    const DropdownMenuItem(value: 'Photography', child: Text('Photography')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _filterUsers();
                    });
                    debugPrint('Selected category: $value');
                  },
                ),
                DropdownButton<String>(
                  hint: const Text('Location'),
                  value: _selectedLocation,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    const DropdownMenuItem(value: 'New York', child: Text('New York')),
                    const DropdownMenuItem(value: 'London', child: Text('London')),
                    const DropdownMenuItem(value: 'Tokyo', child: Text('Tokyo')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value;
                      _filterUsers();
                    });
                    debugPrint('Selected location: $value');
                  },
                ),
                DropdownButton<String>(
                  hint: const Text('Rating'),
                  value: _selectedRating,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    const DropdownMenuItem(value: '4+', child: Text('4+')),
                    const DropdownMenuItem(value: '3+', child: Text('3+')),
                    const DropdownMenuItem(value: '2+', child: Text('2+')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRating = value;
                      _filterUsers();
                    });
                    debugPrint('Selected rating: $value');
                  },
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAvailableOnly = !_showAvailableOnly;
                      _filterUsers();
                    });
                    debugPrint('Availability toggled: $_showAvailableOnly');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _showAvailableOnly ? Colors.pink[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'AVAIL',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Search Result',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                  : _filteredUsers.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  debugPrint('Building UserCard for user: ${user.fullName}, UID: ${user.uid}');
                  return UserCard(
                    user: user,
                    isSearchResult: true,
                    onRequestSkill: () => _requestSkill(user),
                    onViewProfile: () {
                      debugPrint('View profile for user: ${user.fullName}, UID: ${user.uid}');
                      FocusScope.of(context).unfocus();
                      Navigator.pushNamed(
                        context,
                        Routes.skillDetail,
                        arguments: {'user': user},
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          debugPrint('Bottom navigation tapped: $index');
          if (index == 0) {
            Navigator.pushNamed(context, Routes.home);
          } else if (index == 1) {
            Navigator.pushNamed(context, Routes.requests);
          } else if (index == 2) {
            Navigator.pushNamed(context, Routes.messageList);
          } else if (index == 3) {
            Navigator.pushNamed(context, Routes.profile);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }
}