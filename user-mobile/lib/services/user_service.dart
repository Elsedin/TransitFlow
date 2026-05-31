import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../utils/api_error.dart';
import 'auth_service.dart';

class UserService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  Future<User> getCurrentUser() async {
    final token = await _getToken();
    if (token == null) throw Exception('Niste prijavljeni');

    final response = await http.get(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/userprofile/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Učitavanje profila nije uspjelo'));
    }
  }

  Future<User> updateProfile(UpdateUserProfileRequest request) async {
    final token = await _getToken();
    if (token == null) throw Exception('Niste prijavljeni');

    final response = await http.put(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/userprofile/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Ažuriranje profila nije uspjelo'));
    }
  }
}
