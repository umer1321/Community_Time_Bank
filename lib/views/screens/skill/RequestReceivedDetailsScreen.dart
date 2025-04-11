import 'package:flutter/material.dart';
import '../../../models/firebase_service.dart';
import '../../../models/request_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/routes.dart';

class RequestReceivedDetailsScreen extends StatefulWidget {
  final String requestId;

  const RequestReceivedDetailsScreen({super.key, required this.requestId});

  @override
  State<RequestReceivedDetailsScreen> createState() => _RequestReceivedDetailsScreenState();
}

class _RequestReceivedDetailsScreenState extends State<RequestReceivedDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  RequestModel? _request;
  bool _isLoading = true;
  bool _sessionReminder = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequest();
  }

  Future<void> _fetchRequest() async {
    setState(() {
      _isLoading = true;
    });
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
      print('Fetched request: ${request.id}');

      setState(() {
        _request = request;
        _sessionReminder = request.sessionReminder;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching request: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching request: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching request: $e')),
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

  Future<void> _completeSession() async {
    try {
      await _firebaseService.updateRequest(_request!.id, {'status': 'completed'});
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete session')),
      );
    }
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

      // Create or get the conversation between the current user and the sender user
      String conversationId = await _firebaseService.createConversation(
        currentUserId,
        _request!.senderId,
      );

      // Navigate to the ChatScreen with the conversationId and senderUser
      Navigator.pushNamed(
        context,
        Routes.chat,
        arguments: {
          'conversationId': conversationId,
          'otherUser': _request!.senderUser,
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

    if (_request == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Request not found.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _request!.senderUser!.fullName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined, color: Colors.blue),
            onPressed: _navigateToChat, // Updated to navigate to ChatScreen
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.red),
            onPressed: () {
              // Implement favorite action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favorite action not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: _request!.senderUser!.profilePictureUrl.isNotEmpty
                      ? NetworkImage(_request!.senderUser!.profilePictureUrl)
                      : const NetworkImage('https://via.placeholder.com/150'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _request!.senderUser!.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _request!.senderUser!.location ?? 'Columbia',
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
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Skill Requested',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
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
            const Text(
              'Session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _request!.sessionDate.split(' ')[0],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _request!.sessionTime,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Additional Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _request!.additionalNotes,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rating',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // View all ratings action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('View all ratings not implemented yet')),
                    );
                  },
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < _request!.senderUser!.rating.floor()
                        ? Icons.star
                        : (index < _request!.senderUser!.rating ? Icons.star_half : Icons.star_border),
                    size: 20,
                    color: Colors.amber,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  "${_request!.senderUser!.rating.toStringAsFixed(1)}/5",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Turn on session reminders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_sessionReminder)
                      const Text(
                        'You will receive a reminder 30 minutes before the session.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      )
                    else
                      const Text(
                        'You will not receive a reminder for this session.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      )
                  ],
                ),
                Switch(
                  value: _sessionReminder,
                  onChanged: (value) {
                    _updateReminder(value);
                  },
                  activeColor: Colors.red,
                  activeTrackColor: Colors.red.withOpacity(0.5),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey[300],
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completeSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Done Session',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}