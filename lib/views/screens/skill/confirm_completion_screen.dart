import 'package:flutter/material.dart';
import '../../../models/firebase_service.dart';
import '../../../models/user_model.dart';
import '../../../utils/routes.dart';

class ConfirmCompletionScreen extends StatefulWidget {
  final String requestId;
  final String targetUserId;

  const ConfirmCompletionScreen({
    super.key,
    required this.requestId,
    required this.targetUserId,
  });

  @override
  State<ConfirmCompletionScreen> createState() => _ConfirmCompletionScreenState();
}

class _ConfirmCompletionScreenState extends State<ConfirmCompletionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoadingYes = false;
  bool _isLoadingNo = false;

  Future<void> _confirmSessionCompletion(BuildContext context) async {
    setState(() {
      _isLoadingYes = true;
    });

    try {
      String? currentUserId = _firebaseService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Update the request status to "completed"
      await _firebaseService.updateRequest(widget.requestId, {
        'status': 'completed',
      });

      // Adjust time credits: deduct 1 from sender, add 1 to receiver
      await _firebaseService.adjustTimeCredits(currentUserId, widget.targetUserId);

      // Fetch the reviewed user's details
      UserModel reviewedUser = await _firebaseService.getUserById(widget.targetUserId);

      // Navigate to the RateYourExperienceScreen using named route
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          Routes.rateReview,
          arguments: {
            'requestId': widget.requestId,
            'reviewedUser': reviewedUser,
            'reviewerId': currentUserId,
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingYes = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing session: $e')),
        );
      }
    }
  }

  Future<void> _markSessionNotCompleted(BuildContext context) async {
    setState(() {
      _isLoadingNo = true;
    });

    try {
      // Update the request status to "not_completed"
      await _firebaseService.updateRequest(widget.requestId, {
        'status': 'not_completed',
      });

      // Show message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session marked as not completed')),
        );
      }

      // Navigate back to the previous screen
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoadingNo = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking session as not completed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background content (RequestSentDetailsScreen content)
          // This will be partially visible behind the dialog
          const SizedBox.expand(),
          // Dialog overlay
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Confirm Session Completion',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Here you can confirm session completion with skill credit.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoadingNo || _isLoadingYes
                              ? null
                              : () => _markSessionNotCompleted(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isLoadingNo
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.red,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            'No, It Isn’t!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoadingYes || _isLoadingNo
                              ? null
                              : () => _confirmSessionCompletion(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isLoadingYes
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            'Yes, It Is!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}