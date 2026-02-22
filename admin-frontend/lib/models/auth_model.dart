class AuthModel {
  final String username;
  final String password;

  AuthModel({
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

class AuthResponse {
  final String token;
  final String username;
  final DateTime expiresAt;

  AuthResponse({
    required this.token,
    required this.username,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      username: json['username'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
