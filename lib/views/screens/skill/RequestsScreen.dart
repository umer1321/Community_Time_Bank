// lib/views/screens/skill/request_skill_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/routes.dart';
import '../../../models/firebase_service.dart';
import '../../../models/request_model.dart';
import '../../../models/navigation_service.dart';
import 'package:community_time_bank/views/screens/skill/RequestReceivedDetailsScreen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  List<RequestModel> _sentRequests = [];
  List<RequestModel> _receivedRequests = [];
  bool _isLoading = true;
  int _selectedIndex = 1; // For bottom navigation bar
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.pushReplacementNamed(context, Routes.login);
        return;
      }

      setState(() {
        _isLoading = true;
      });

      List<RequestModel> sentRequests = await _firebaseService.getSentRequests();
      List<RequestModel> receivedRequests = await _firebaseService.getReceivedRequests();

      setState(() {
        _sentRequests = sentRequests;
        _receivedRequests = receivedRequests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load requests')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateReminder(String requestId, bool reminder) async {
    try {
      await _firebaseService.updateRequest(requestId, {'sessionReminder': reminder});
      _loadRequests(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update reminder')),
      );
    }
  }

  Future<void> _withdrawRequest(String requestId) async {
    try {
      await _firebaseService.withdrawSkillRequest(requestId);
      _loadRequests(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to withdraw request')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, Routes.home);
        break;
      case 1:
      // Already on Requests
        break;
      case 2:
        Navigator.pushNamed(context, Routes.messageList);
        break;
      case 3:
        Navigator.pushNamed(context, Routes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Community Time Bank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Requests',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.6),
                  spreadRadius: 2,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],

            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(40),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: const [
                Tab(text: 'Requests Sent'),
                Tab(text: 'Requests Received'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.red))
                : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(_sentRequests, isSent: true),
                _buildRequestsList(_receivedRequests, isSent: false),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 0,
        onTap: _onItemTapped,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }

  Widget _buildRequestsList(List<RequestModel> requests, {required bool isSent}) {
    if (requests.isEmpty) {
      return Center(
        child: Text(
          'No ${isSent ? 'sent' : 'received'} requests',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final user = isSent ? request.targetUser : request.senderUser;
        final isValidRequestId = request.id != null && request.id!.isNotEmpty;

        if (user == null) {
          return const SizedBox.shrink(); // Skip if user data is missing
        }

        // Status indicator color based on request status
        Color statusColor = Colors.orange;
        String statusText = "Pending";
        if (request.status == "accepted") {
          statusColor = Colors.green;
          statusText = "Accepted";
        } else if (request.status == "completed") {
          statusColor = Colors.green;
          statusText = "Done";
        } else if (request.status == "withdrawn") {
          statusColor = Colors.grey;
          statusText = "Withdrawn";
        }

        // Fetch one skill for "Skill Offered" and "Skill Requested"
        String skillOffered = request.skillOffered.isNotEmpty
            ? request.skillOffered
            : (user.skillsCanTeach.isNotEmpty ? user.skillsCanTeach.first : 'N/A');
        String skillRequested = request.skillWanted.isNotEmpty
            ? request.skillWanted
            : (user.skillsWantToLearn.isNotEmpty ? user.skillsWantToLearn.first : 'N/A');

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Profile Picture
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: user.profilePictureUrl.isNotEmpty
                          ? NetworkImage(user.profilePictureUrl)
                          : const NetworkImage('https://via.placeholder.com/150'),
                    ),
                    const SizedBox(width: 10),
                    // User Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          if (!isValidRequestId) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Invalid request ID',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Skills exchange
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skill Offered',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            skillOffered,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    // Arrow
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.red[300],
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skill Requested',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            skillRequested,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // View Details button
              Container(
                width: double.infinity,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: TextButton(
                  onPressed: isValidRequestId
                      ? () {
                    print('Navigating to ${isSent ? "RequestSentDetailsScreen" : "RequestReceivedDetailsScreen"} with requestId: ${request.id}');
                    // Navigate based on the tab
                    if (isSent) {
                      Navigator.pushNamed(
                        context,
                        Routes.requestSkill,
                        arguments: {'requestId': request.id},
                      );
                    } else {
                      Navigator.pushNamed(
                        context,
                        Routes.requestReceivedDetails,
                        arguments: {'requestId': request.id},
                      );
                    }
                  }
                      : null, // Disable the button if requestId is invalid
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}