import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/auth_model.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'auth_username';
  static const String _expiresAtKey = 'auth_expires_at';

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<AuthResponse?> login(String username, String password) async {
    try {
      final url = '${AppConfig.apiBaseUrl}/auth/login';
      _log('[AuthService] Login URL: $url');
      _log('[AuthService] Username: $username');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(AuthModel(
          username: username,
          password: password,
        ).toJson()),
      );

      _log('[AuthService] Response status: ${response.statusCode}');
      _log('[AuthService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(data);
        
        await _saveAuthData(authResponse);
        return authResponse;
      } else {
        _log('[AuthService] Login failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _log('[AuthService] Login error: $e');
      return null;
    }
  }

  Future<void> _saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, authResponse.token);
    await prefs.setString(_usernameKey, authResponse.username);
    await prefs.setString(_expiresAtKey, authResponse.expiresAt.toIso8601String());
    _log('[AuthService] Saved auth data. Token expires at: ${authResponse.expiresAt}');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    _log('[AuthService] Checking authentication. Token exists: ${token != null && token.isNotEmpty}');
    
    if (token == null || token.isEmpty) {
      _log('[AuthService] No token found, user not authenticated');
      return false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final expiresAtString = prefs.getString(_expiresAtKey);
    
    if (expiresAtString != null) {
      try {
        final expiresAt = DateTime.parse(expiresAtString);
        final now = DateTime.now().toUtc();
        
        _log('[AuthService] Token expires at: $expiresAt, current time: $now');
        
        if (now.isAfter(expiresAt)) {
          _log('[AuthService] Token has expired, logging out');
          await logout();
          return false;
        }
        
        final timeUntilExpiry = expiresAt.difference(now);
        _log('[AuthService] Token is valid for ${timeUntilExpiry.inMinutes} more minutes');
      } catch (e) {
        _log('[AuthService] Error parsing expiresAt: $e');
      }
    }
    
    try {
      _log('[AuthService] Validating token with API...');
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/dashboard/metrics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 3));
      
      _log('[AuthService] API response status: ${response.statusCode}');
      
      if (response.statusCode == 401 || response.statusCode == 403) {
        _log('[AuthService] Token invalid (${response.statusCode}), logging out');
        await logout();
        return false;
      }
      
      final isAuthenticated = response.statusCode == 200;
      _log('[AuthService] Authentication result: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      _log('[AuthService] Token validation failed: $e');
      _log('[AuthService] Logging out due to error');
      await logout();
      return false;
    }
  }
  
  Future<void> clearAuthData() async {
    await logout();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_expiresAtKey);
    _log('[AuthService] Logged out and cleared all auth data');
  }
}
