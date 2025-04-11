// lib/views/screens/skill/search_skills_screen.dart
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../utils/routes.dart';

class SearchSkillsScreen extends StatelessWidget {
  const SearchSkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Skills',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Search Skills Screen - Coming Soon'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, Routes.home);
          } else if (index == 1) {
            Navigator.pushNamed(context, Routes.requests);
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
      ),
    );
  }
}