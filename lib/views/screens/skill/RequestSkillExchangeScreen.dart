// lib/views/screens/skill/RequestSkillExchangeScreen.dart
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/routes.dart';
import '../../../models/navigation_service.dart'; // Add NavigationService import

class RequestSkillExchangeScreen extends StatefulWidget {
  final UserModel targetUser;
  final String? preSelectedSkillOffered;
  final String? preSelectedSkillWanted;

  const RequestSkillExchangeScreen({
    super.key,
    required this.targetUser,
    this.preSelectedSkillOffered,
    this.preSelectedSkillWanted,
  });

  @override
  State<RequestSkillExchangeScreen> createState() => _RequestSkillExchangeScreenState();
}

class _RequestSkillExchangeScreenState extends State<RequestSkillExchangeScreen> {
  String? _selectedSkillOffered;
  String? _selectedSkillWanted;
  final _additionalNoteController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedSkillOffered = widget.preSelectedSkillOffered;
    _selectedSkillWanted = widget.preSelectedSkillWanted;
  }

  @override
  void dispose() {
    _additionalNoteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => NavigationService().goBack(), // Use NavigationService
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView( // Wrap Column in SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request a Skill Exchange',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Session booking field
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: const Text('Book a Session'),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(height: 24),

              // Skill Offered Section
              const Text(
                'Skill Offered',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedSkillOffered,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: InputBorder.none,
                  ),
                  items: widget.targetUser.skillsCanTeach.map((skill) {
                    return DropdownMenuItem<String>(
                      value: skill,
                      child: Text(skill),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSkillOffered = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a skill';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Skill Wanted Section
              const Text(
                'Skill Requested',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedSkillWanted,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: InputBorder.none,
                  ),
                  items: widget.targetUser.skillsWantToLearn.map((skill) {
                    return DropdownMenuItem<String>(
                      value: skill,
                      child: Text(skill),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSkillWanted = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a skill';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Additional Notes
              const Text(
                'Additional Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _additionalNoteController,
                  decoration: const InputDecoration(
                    hintText: 'write here',
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 24), // Replace Spacer with SizedBox

              // Next Button
              ElevatedButton(
                onPressed: (_selectedSkillOffered != null && _selectedSkillWanted != null)
                    ? () {
                  NavigationService().navigateTo( // Use NavigationService
                    Routes.bookSession,
                    arguments: {
                      'targetUser': widget.targetUser,
                      'skillOffered': _selectedSkillOffered,
                      'skillWanted': _selectedSkillWanted,
                      'additionalNote': _additionalNoteController.text,
                      'selectedDate': _selectedDate,
                    },
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6), // Blue color from the mockup
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16), // Add some padding at the bottom
            ],
          ),
        ),
      ),
    );
  }
}