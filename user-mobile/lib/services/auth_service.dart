import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/auth_model.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'user_id';
  static const String _expiresAtKey = 'expires_at';

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final loginResponse = LoginResponse.fromJson(json.decode(response.body));
      await _saveAuthData(loginResponse);
      return loginResponse;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/user/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final registerResponse = RegisterResponse.fromJson(json.decode(response.body));
      await _saveAuthDataFromRegister(registerResponse);
      return registerResponse;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Registration failed');
    }
  }

  Future<void> _saveAuthData(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.token);
    await prefs.setString(_usernameKey, response.username);
    if (response.userId != null) {
      await prefs.setInt(_userIdKey, response.userId!);
    }
    await prefs.setString(_expiresAtKey, response.expiresAt.toIso8601String());
  }

  Future<void> _saveAuthDataFromRegister(RegisterResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.token);
    await prefs.setString(_usernameKey, response.username);
    await prefs.setInt(_userIdKey, response.userId);
    await prefs.setString(_expiresAtKey, response.expiresAt.toIso8601String());
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final expiresAtString = prefs.getString(_expiresAtKey);
    
    if (expiresAtString != null) {
      try {
        final expiresAt = DateTime.parse(expiresAtString);
        final now = DateTime.now().toUtc();
        
        if (now.isAfter(expiresAt)) {
          await logout();
          return false;
        }
      } catch (e) {
        return false;
      }
    }

    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_expiresAtKey);
  }
}
