import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/favorite_line_model.dart';
import 'auth_service.dart';

class FavoriteService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  Future<List<FavoriteLine>> getAll() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/favorites/lines?page=1&pageSize=100'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? const <dynamic>[]);
      return items.map((json) => FavoriteLine.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load favorite lines: ${response.statusCode}');
    }
  }

  Future<bool> isFavorite(int transportLineId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/favorites/lines/check/$transportLineId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as bool;
    } else {
      throw Exception('Failed to check favorite status: ${response.statusCode}');
    }
  }

  Future<FavoriteLine> addFavorite(int transportLineId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final requestBody = {
      'transportLineId': transportLineId,
    };

    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/favorites/lines'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return FavoriteLine.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to add favorite line');
    }
  }

  Future<void> removeFavorite(int transportLineId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/favorites/lines/$transportLineId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to remove favorite line');
    }
  }
}
