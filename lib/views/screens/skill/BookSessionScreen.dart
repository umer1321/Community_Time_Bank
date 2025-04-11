// lib/views/screens/skill/BookSessionScreen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/routes.dart';
import '../../../models/firebase_service.dart';
import '../../../models/navigation_service.dart';
import '../../widgets/custom_button.dart';

class BookSessionScreen extends StatefulWidget {
  final UserModel targetUser;
  final String skillOffered;
  final String skillWanted;
  final String additionalNote;

  const BookSessionScreen({
    super.key,
    required this.targetUser,
    required this.skillOffered,
    required this.skillWanted,
    required this.additionalNote,
  });

  @override
  State<BookSessionScreen> createState() => _BookSessionScreenState();
}

class _BookSessionScreenState extends State<BookSessionScreen> {
  DateTime? _selectedDate;
  final List<String> _selectedTimeSlots = [];
  final List<String> _availableTimeSlots = [
    '9:00 AM',
    '11:00 AM',
    '1:00 PM',
    '3:00 PM',
    '5:00 PM',
    '7:00 PM',
    '9:00 PM',
    '11:00 PM',
  ];

  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final int _daysToShow = 30; // Show a month of dates
  final ScrollController _scrollController = ScrollController();
  String _currentMonth = '';
  bool _isLoading = false;
  bool _sessionReminder = false;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonth = DateFormat('MMMM yyyy').format(_selectedDate ?? DateTime.now());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateCurrentMonth() {
    setState(() {
      _currentMonth = DateFormat('MMMM yyyy').format(_selectedDate ?? DateTime.now());
    });
  }

  List<DateTime> _getDates() {
    final now = DateTime.now();
    return List.generate(_daysToShow, (index) => now.add(Duration(days: index)));
  }

  Future<void> _saveRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      await NavigationService().navigateToAndRemove(Routes.login);
      return;
    }

    if (_selectedDate == null || _selectedTimeSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and at least one time slot')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sessionDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final sessionTime = _selectedTimeSlots.join(', ');

      String requestId = await _firebaseService.createSkillRequest(
        requesterUid: currentUser.uid,
        targetUid: widget.targetUser.uid,
        skillOffered: widget.skillOffered,
        skillWanted: widget.skillWanted,
        skillRequested: widget.skillWanted,
        sessionDate: sessionDate,
        sessionTime: sessionTime,
        additionalNotes: widget.additionalNote,
        sessionReminder: _sessionReminder,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent successfully')),
      );

      await NavigationService().navigateTo(
        Routes.requests,
      );

      await NavigationService().navigateTo(
        Routes.requestSentDetails,
        arguments: {'requestId': requestId},
      );
    } catch (e) {
      print('Error saving request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = _getDates();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService().goBack(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book a One Hour Session',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _currentMonth,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 76,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification) {
                    final visibleDates = dates.where((date) {
                      final itemPosition = (date.difference(dates[0]).inDays * 55.0);
                      return itemPosition >= _scrollController.offset &&
                          itemPosition < _scrollController.offset + _scrollController.position.viewportDimension;
                    }).toList();

                    if (visibleDates.isNotEmpty) {
                      final middleDate = visibleDates[visibleDates.length ~/ 2];
                      final visibleMonth = DateFormat('MMMM yyyy').format(middleDate);
                      if (visibleMonth != _currentMonth) {
                        setState(() {
                          _currentMonth = visibleMonth;
                        });
                      }
                    }
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final weekDay = _weekDays[date.weekday - 1];
                    final isSelected = _selectedDate != null &&
                        _selectedDate!.day == date.day &&
                        _selectedDate!.month == date.month &&
                        _selectedDate!.year == date.year;

                    return Container(
                      width: 55,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Text(
                            weekDay,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                                _currentMonth = DateFormat('MMMM yyyy').format(date);
                              });
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: isSelected ? AppConstants.primaryBlue : Colors.transparent,
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Time Slots',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3,
                ),
                itemCount: _availableTimeSlots.length,
                itemBuilder: (context, index) {
                  final slot = _availableTimeSlots[index];
                  final isSelected = _selectedTimeSlots.contains(slot);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTimeSlots.remove(slot);
                        } else {
                          _selectedTimeSlots.add(slot);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppConstants.primaryBlue : Colors.grey[300]!,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? AppConstants.primaryBlue.withOpacity(0.1) : Colors.transparent,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: isSelected ? AppConstants.primaryBlue : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Set Session Reminder'),
              value: _sessionReminder,
              onChanged: (value) {
                setState(() {
                  _sessionReminder = value;
                });
              },
              activeColor: AppConstants.primaryBlue,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Next',
              color: AppConstants.primaryBlue,
              onPressed: _isLoading ? null : _saveRequest,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}