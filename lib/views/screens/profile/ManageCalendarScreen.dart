// lib/views/screens/manage_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/firebase_service.dart';

class ManageCalendarScreen extends StatefulWidget {
  const ManageCalendarScreen({super.key});

  @override
  State<ManageCalendarScreen> createState() => _ManageCalendarScreenState();
}

class _ManageCalendarScreenState extends State<ManageCalendarScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  DateTime _focusedDay = DateTime.now();
  List<DateTime> _availableDays = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  Future<void> _fetchAvailability() async {
    try {
      String? currentUserId = _firebaseService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      List<DateTime> availableDays = await _firebaseService.getUserAvailability(currentUserId);
      setState(() {
        _availableDays = availableDays;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load availability: $e')),
      );
    }
  }

  Future<void> _updateAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? currentUserId = _firebaseService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Convert List<DateTime> to List<String> with only the date part (YYYY-MM-DD)
      List<String> availability = _availableDays.map((date) {
        return DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
      }).toList();

      await _firebaseService.updateUserAvailability(currentUserId, availability.cast<DateTime>());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Availability updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update availability: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Manage Calendar',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return _availableDays.any((d) =>
                d.year == day.year && d.month == day.month && d.day == day.day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                  // Normalize the selected day to remove time components
                  final normalizedSelectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                  if (_availableDays.any((d) =>
                  d.year == selectedDay.year &&
                      d.month == selectedDay.month &&
                      d.day == selectedDay.day)) {
                    _availableDays.removeWhere((d) =>
                    d.year == selectedDay.year &&
                        d.month == selectedDay.month &&
                        d.day == selectedDay.day);
                  } else {
                    _availableDays.add(normalizedSelectedDay);
                  }
                });
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Save Availability',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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