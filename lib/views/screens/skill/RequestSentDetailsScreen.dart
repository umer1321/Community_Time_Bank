import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../models/firebase_service.dart';
import '../../../models/request_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/routes.dart';
import 'package:community_time_bank/views/screens/skill/confirm_completion_screen.dart';

class RequestSentDetailsScreen extends StatefulWidget {
  final String requestId;

  const RequestSentDetailsScreen({super.key, required this.requestId});

  @override
  State<RequestSentDetailsScreen> createState() => _RequestSentDetailsScreenState();
}

class _RequestSentDetailsScreenState extends State<RequestSentDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  RequestModel? _request;
  bool _isLoading = true;
  bool _sessionReminder = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  Future<void> _fetchRequestDetails() async {
    try {
      print('Fetching request with requestId: ${widget.requestId}');

      if (widget.requestId.isEmpty) {
        print('RequestId validation failed: ${widget.requestId}');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid request ID: requestId is empty';
        });
        return;
      }

      final request = await _firebaseService.getRequestById(widget.requestId);
      print('Fetched request: ${request.id}, Status: ${request.status}');

      setState(() {
        _request = request;
        _sessionReminder = request.sessionReminder;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching request details: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load request details: $e';
      });
    }
  }

  Future<void> _withdrawRequest() async {
    try {
      await _firebaseService.withdrawSkillRequest(_request!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request withdrawn')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error withdrawing request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to withdraw request')),
      );
    }
  }

  Future<void> _updateReminder(bool value) async {
    try {
      await _firebaseService.updateRequest(_request!.id, {'sessionReminder': value});
      setState(() {
        _sessionReminder = value;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update reminder')),
      );
    }
  }

  void _confirmCompletion() {
    Navigator.pushNamed(
      context,
      Routes.confirmCompletion,
      arguments: {
        'requestId': _request!.id,
        'targetUserId': _request!.receiverId,
      },
    );
  }

  void _editRequest() {
    // Implement edit functionality
  }

  Future<void> _navigateToChat() async {
    try {
      String? currentUserId = _firebaseService.getCurrentUserId();
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      // Create or get the conversation between the current user and the target user
      String conversationId = await _firebaseService.createConversation(
        currentUserId,
        _request!.receiverId,
      );

      // Navigate to the ChatScreen with the conversationId and targetUser
      Navigator.pushNamed(
        context,
        Routes.chat,
        arguments: {
          'conversationId': conversationId,
          'otherUser': _request!.targetUser,
        },
      );
    } catch (e) {
      print('Error navigating to chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open chat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    if (_errorMessage != null) {
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
            'Error',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Determine if the "Confirm Completion" button should be shown
    bool canConfirmCompletion = false;
    try {
      final sessionDateTime = DateFormat('yyyy-MM-dd hh:mm a').parse('${_request!.sessionDate} ${_request!.sessionTime}');
      canConfirmCompletion = _request!.status == 'accepted' && sessionDateTime.isBefore(DateTime.now());
      print('Can confirm completion: $canConfirmCompletion');
      print('Status: ${_request!.status}');
      print('Session DateTime: $sessionDateTime');
      print('Current DateTime: ${DateTime.now()}');
    } catch (e) {
      print('Error parsing session date/time: $e');
      canConfirmCompletion = false;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Requests Sent Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchRequestDetails, // Add refresh button to manually fetch updated data
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
            onPressed: _navigateToChat,
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.red),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favorite action not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: _request!.targetUser!.profilePictureUrl.isNotEmpty
                      ? NetworkImage(_request!.targetUser!.profilePictureUrl)
                      : const NetworkImage('https://via.placeholder.com/150'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _request!.targetUser!.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _request!.targetUser!.location ?? 'Colombia',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Skill Requested',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _request!.skillWanted,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Session',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _request!.sessionDate.split(' ')[0],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _request!.sessionTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Additional Notes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
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
                _request!.additionalNotes,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Rating',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < _request!.targetUser!.rating.floor()
                        ? Icons.star
                        : (index < _request!.targetUser!.rating ? Icons.star_half : Icons.star_border),
                    size: 16,
                    color: Colors.amber,
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  '${_request!.targetUser!.rating.toStringAsFixed(1)}/5',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Turn on session reminders',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _sessionReminder,
                  onChanged: _request!.status == 'completed'
                      ? null
                      : (value) {
                    _updateReminder(value);
                  },
                  activeColor: Colors.blue,
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey[300],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _request!.status == 'completed'
                  ? 'Session completed'
                  : _sessionReminder
                  ? 'Now you receive reminders for this session'
                  : 'You won\'t receive reminders for this session',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _request!.status == 'completed' ? null : _editRequest,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _request!.status == 'completed' ? null : _withdrawRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Withdraw',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (canConfirmCompletion) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmCompletion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Confirm Completion',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, Routes.home);
          } else if (index == 2) {
            Navigator.pushNamed(context, Routes.messageList);
          } else if (index == 3) {
            Navigator.pushNamed(context, Routes.profile, arguments: null);
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
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }
}