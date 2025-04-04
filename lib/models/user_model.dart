// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final List<String> skillsCanTeach;
  final List<String> skillsWantToLearn;
  final String role;
  final Map<String, List<String>> availability;
  final int timeCredits;
  final bool hasSeenWelcomePopup;
  final String profilePictureUrl;
  final double rating;
  final String? location; // Added field
  final String? bio; // Added field

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
      'availability': availability,
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
      availability: Map<String, List<String>>.from(map['availability']?.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
      ) ??
          {}),
      timeCredits: map['timeCredits'] ?? 0,
      hasSeenWelcomePopup: map['hasSeenWelcomePopup'] ?? false,
      profilePictureUrl: map['profilePictureUrl'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      location: map['location'],
      bio: map['bio'],
    );
  }
}