import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/auth_model.dart';
import '../utils/api_error.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'user_id';
  static const String _expiresAtKey = 'expires_at';

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/auth/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final loginResponse = LoginResponse.fromJson(json.decode(response.body));
      await _saveAuthData(loginResponse);
      return loginResponse;
    } else {
      throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Prijava nije uspjela'));
    }
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/auth/user/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final registerResponse = RegisterResponse.fromJson(json.decode(response.body));
      await _saveAuthDataFromRegister(registerResponse);
      return registerResponse;
    } else {
      throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Registracija nije uspjela'));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Niste prijavljeni');

    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/auth/user/change-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Promjena lozinke nije uspjela'));
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/auth/user/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email.trim()}),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      return decoded['message'] as String? ??
          'Ako postoji račun sa tom email adresom, poslat ćemo vam kod za reset lozinke.';
    }

    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Slanje koda nije uspjelo'));
  }

  Future<void> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/auth/user/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email.trim(),
        'resetCode': resetCode.trim(),
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Reset lozinke nije uspio'));
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      
      if (token == null || token.isEmpty) {
        return false;
      }

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
          await logout();
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('isAuthenticated error: $e');
      }
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_expiresAtKey);
  }
}
