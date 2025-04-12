// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final List<String> skillsCanTeach;
  final List<String> skillsWantToLearn;
  final String role;
  final List<DateTime> availability; // Updated from Map<String, List<String>>
  final int timeCredits;
  final bool hasSeenWelcomePopup;
  final String profilePictureUrl;
  final double rating;
  final String? location; // Optional field
  final String? bio; // Optional field

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.skillsCanTeach,
    required this.skillsWantToLearn,
    required this.role,
    required this.availability,
    required this.timeCredits,
    required this.hasSeenWelcomePopup,
    required this.profilePictureUrl,
    required this.rating,
    this.location,
    this.bio,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'skillsCanTeach': skillsCanTeach,
      'skillsWantToLearn': skillsWantToLearn,
      'role': role,
      'availability': availability.map((date) => date.toIso8601String().split('T')[0]).toList(),
      'timeCredits': timeCredits,
      'hasSeenWelcomePopup': hasSeenWelcomePopup,
      'profilePictureUrl': profilePictureUrl,
      'rating': rating,
      'location': location,
      'bio': bio,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {required String uid}) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      skillsCanTeach: List<String>.from(map['skillsCanTeach'] ?? []),
      skillsWantToLearn: List<String>.from(map['skillsWantToLearn'] ?? []),
      role: map['role'] ?? '',
      availability: (map['availability'] as List<dynamic>?)?.map((dateStr) => DateTime.parse(dateStr as String)).toList() ?? [],
      timeCredits: map['timeCredits'] ?? 0,
      hasSeenWelcomePopup: map['hasSeenWelcomePopup'] ?? false,
      profilePictureUrl: map['profilePictureUrl'] ?? 'https://picsum.photos/300', // Default value
      rating: (map['rating'] ?? 0.0).toDouble(),
      location: map['location'],
      bio: map['bio'],
    );
  }
}