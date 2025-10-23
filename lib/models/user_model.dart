class UserModel {
  final String? uid; // Changed to nullable
  final String? email;
  final String? displayName;
  final String? phoneNumber; // Assuming "phone numbers" refers to this single field for now

  UserModel({
    this.uid, // No longer required
    this.email,
    this.displayName,
    this.phoneNumber,
  });

  // Factory constructor to create a UserModel from a JSON object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // UID is now optional from the API JSON
    final uidValue = json['id'] as String? ?? json['uid'] as String?;
    // Email and phoneNumber are the primary fields to fetch as per the request
    final emailValue = json['email'] as String?;
    // Map backend snake_case fields to model camelCase fields
    final phoneNumberValue = json['phone_number'] as String?;
    final displayNameValue = json['full_name'] as String?;

    return UserModel(
      uid: uidValue,
      email: emailValue,
      displayName: displayNameValue,
      phoneNumber: phoneNumberValue,
    );
  }

  // Method to convert UserModel instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'uid': uid, // Will be null if uid is null
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
    };
  }

  // Method to create a copy of UserModel instance with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserModel &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName &&
      other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      phoneNumber.hashCode;
  }
}
