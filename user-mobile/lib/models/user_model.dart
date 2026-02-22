class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String fullName;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final int purchaseCount;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    required this.fullName,
    this.phoneNumber,
    required this.createdAt,
    this.lastLoginAt,
    required this.isActive,
    required this.purchaseCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt'] as String) : null,
      isActive: json['isActive'] as bool,
      purchaseCount: json['purchaseCount'] as int,
    );
  }
}

class UpdateUserProfileRequest {
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;

  UpdateUserProfileRequest({
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
}
