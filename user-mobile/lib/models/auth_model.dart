class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
}

class LoginResponse {
  final String token;
  final String username;
  final int? userId;
  final DateTime expiresAt;

  LoginResponse({
    required this.token,
    required this.username,
    this.userId,
    required this.expiresAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      username: json['username'] as String,
      userId: json['userId'] as int?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

class RegisterResponse {
  final int userId;
  final String username;
  final String email;
  final String token;
  final DateTime expiresAt;

  RegisterResponse({
    required this.userId,
    required this.username,
    required this.email,
    required this.token,
    required this.expiresAt,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      userId: json['userId'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
