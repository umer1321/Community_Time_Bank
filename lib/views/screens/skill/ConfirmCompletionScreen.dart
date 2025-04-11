// lib/views/screens/skill/ConfirmCompletionScreen.dart
import 'package:flutter/material.dart';
import '../../../models/firebase_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/routes.dart';

class ConfirmCompletionScreen extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  ConfirmCompletionScreen({super.key});

  Future<void> _confirmCompletion(BuildContext context, String requestId, String targetUserId) async {
    try {
      await _firebaseService.updateRequest(requestId, {'status': 'completed'});
      Navigator.pushNamed(
        context,
        Routes.review,
        arguments: {
          'requestId': requestId,
          'targetUserId': targetUserId,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to confirm completion')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String requestId = args['requestId'] as String;
    final String targetUserId = args['targetUserId'] as String;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Session Completion',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please confirm that the session has been completed successfully.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () => _confirmCompletion(context, requestId, targetUserId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Confirm',
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