class UserProfileModel {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profilePictureUrl;
  final DateTime? dateOfBirth;
  final Map<String, dynamic>? preferences; // e.g., notification settings, language

  UserProfileModel({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profilePictureUrl,
    this.dateOfBirth,
    this.preferences,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return 'N/A';
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      preferences: json['preferences'] != null
          ? Map<String, dynamic>.from(json['preferences'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'profile_picture_url': profilePictureUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'preferences': preferences,
    };
  }
}
