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

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.skillsCanTeach,
    required this.skillsWantToLearn,
    required this.role,
    this.availability = const {},
    this.timeCredits = 0,
  });

  // Convert UserModel to Map for Firestore
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
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      skillsCanTeach: (map['skillsCanTeach'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ??
          [],
      skillsWantToLearn: (map['skillsWantToLearn'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ??
          [],
      role: map['role'] ?? 'User',
      availability: (map['availability'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
          key,
          (value as List<dynamic>?)?.map((item) => item.toString()).toList() ?? [],
        ),
      ) ??
          {},
      timeCredits: map['timeCredits'] ?? 0,
    );
  }
}