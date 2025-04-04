// lib/views/screens/auth/signup_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../utils/constants.dart';
import '../../../utils/routes.dart';
import '../../widgets/custom_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<String> _skillsCanTeach = [];
  final List<String> _skillsWantToLearn = [];
  bool _agreeToTerms = false;
  int _currentStep = 1;
  DateTime? _selectedDate;
  final List<String> _selectedTimeSlots = [];
  final AuthController _authController = AuthController();
  bool _isLoading = false;
  File? _profilePicture; // To store the selected profile picture
  final double _defaultRating = 4.0; // Default rating for new users

  // Sample skills for dropdowns
  final List<String> _availableSkills = [
    'Coding',
    'Cooking',
    'Painting',
    'Yoga',
    'Photography',
  ];

  // Sample time slots
  final List<String> _timeSlots = [
    '10:00 AM',
    '11:00 AM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '5:00 PM',
  ];

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Method to pick an image and persist it
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Get the app's temporary directory
      final tempDir = await getTemporaryDirectory();
      final newFilePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Copy the image to the new location
      File newFile = await File(image.path).copy(newFilePath);
      print("Profile picture saved to: $newFilePath");

      setState(() {
        _profilePicture = newFile;
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 1 && _formKey.currentState!.validate() && _agreeToTerms) {
      setState(() {
        _currentStep = 2;
      });
    } else if (_currentStep == 2 && _selectedDate != null) {
      setState(() {
        _currentStep = 3;
      });
    } else if (_currentStep == 3 && _selectedTimeSlots.isNotEmpty) {
      _signUp();
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _signUp() async {
    setState(() {
      _isLoading = true;
    });
    final String? role = ModalRoute.of(context)?.settings.arguments as String?;
    Map<String, List<String>> availability = {};
    if (_selectedDate != null) {
      availability[_selectedDate!.toIso8601String().split('T')[0]] = _selectedTimeSlots;
    }

    // Verify the profile picture file exists
    if (_profilePicture != null && !await _profilePicture!.exists()) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture file is missing. Please select a new image.')),
      );
      return;
    }

    String? error = await _authController.signUp(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      skillsCanTeach: _skillsCanTeach,
      skillsWantToLearn: _skillsWantToLearn,
      role: role ?? 'User',
      availability: availability,
      profilePicture: _profilePicture,
      rating: _defaultRating,
    );
    setState(() {
      _isLoading = false;
    });
    if (error == null) {
      setState(() {
        _currentStep = 4; // Show success screen
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? role = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: _currentStep == 4
            ? _buildSuccessScreen()
            : _currentStep == 3
            ? _buildTimeSlotsScreen()
            : _currentStep == 2
            ? _buildAvailabilityScreen()
            : _buildPersonalDetailsScreen(role),
      ),
    );
  }

  Widget _buildPersonalDetailsScreen(String? role) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Your Account',
              style: AppConstants.titleStyle,
            ),
            const SizedBox(height: 8),
            const Text(
              'Join the skill-sharing community & start sharing skill!',
              style: AppConstants.subtitleStyle,
            ),
            const SizedBox(height: 32),
            // Profile Picture Upload
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profilePicture != null
                        ? FileImage(_profilePicture!)
                        : const NetworkImage('https://via.placeholder.com/150') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: AppConstants.primaryBlue),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Skills I Can Teach',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _availableSkills.map((skill) {
                return DropdownMenuItem<String>(
                  value: skill,
                  child: Text(skill),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && !_skillsCanTeach.contains(value)) {
                  setState(() {
                    _skillsCanTeach.add(value);
                  });
                }
              },
              validator: (value) {
                if (_skillsCanTeach.isEmpty) {
                  return 'Please select at least one skill';
                }
                return null;
              },
            ),
            Wrap(
              spacing: 8,
              children: _skillsCanTeach.map((skill) {
                return Chip(
                  label: Text(skill),
                  onDeleted: () {
                    setState(() {
                      _skillsCanTeach.remove(skill);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Skills I Want to Learn',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _availableSkills.map((skill) {
                return DropdownMenuItem<String>(
                  value: skill,
                  child: Text(skill),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && !_skillsWantToLearn.contains(value)) {
                  setState(() {
                    _skillsWantToLearn.add(value);
                  });
                }
              },
              validator: (value) {
                if (_skillsWantToLearn.isEmpty) {
                  return 'Please select at least one skill';
                }
                return null;
              },
            ),
            Wrap(
              spacing: 8,
              children: _skillsWantToLearn.map((skill) {
                return Chip(
                  label: Text(skill),
                  onDeleted: () {
                    setState(() {
                      _skillsWantToLearn.remove(skill);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeToTerms = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text('I agree to the terms and conditions'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
              text: 'Next',
              color: AppConstants.primaryBlue,
              onPressed: _agreeToTerms ? _nextStep : () {},
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, Routes.login, arguments: role);
                },
                child: const Text(
                  'Already have an account? Sign In',
                  style: AppConstants.linkStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Your Account',
          style: AppConstants.titleStyle,
        ),
        const SizedBox(height: 8),
        const Text(
          'Set Availability',
          style: AppConstants.subtitleStyle,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2026),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Text(
            _selectedDate == null
                ? 'Select Date'
                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.textGray,
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: 'Next',
                color: AppConstants.primaryBlue,
                onPressed: _selectedDate != null ? _nextStep : () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSlotsScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Your Account',
          style: AppConstants.titleStyle,
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose Available Time Slots',
          style: AppConstants.subtitleStyle,
        ),
        const SizedBox(height: 16),
        Text(
          _selectedDate != null
              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
              : 'No Date Selected',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _timeSlots.length,
            itemBuilder: (context, index) {
              final timeSlot = _timeSlots[index];
              final isSelected = _selectedTimeSlots.contains(timeSlot);
              return ListTile(
                title: Text(timeSlot),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.circle_outlined),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTimeSlots.remove(timeSlot);
                    } else {
                      _selectedTimeSlots.add(timeSlot);
                    }
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.textGray,
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: 'Sign Up',
                color: AppConstants.primaryBlue,
                onPressed: _selectedTimeSlots.isNotEmpty ? _nextStep : () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Account Created Successfully!',
            style: AppConstants.titleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to Community Time Bank! Start exploring and skill-sharing now!',
            style: AppConstants.subtitleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Go to Home',
            color: AppConstants.primaryBlue,
            onPressed: () {
              Navigator.pushReplacementNamed(context, Routes.home);
            },
          ),
        ],
      ),
    );
  }
}