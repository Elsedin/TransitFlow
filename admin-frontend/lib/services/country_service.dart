import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/country_model.dart';
import 'auth_service.dart';

class CountryService {
  Future<List<Country>> getAll({String? search, bool? isActive}) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/countries').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => Country.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load countries');
  }

  Future<Country> create(CreateCountryRequest request) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/countries'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Country.fromJson(data);
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to create country');
  }

  Future<Country> update(int id, UpdateCountryRequest request) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/countries/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Country.fromJson(data);
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to update country');
  }

  Future<void> delete(int id) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/countries/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      return;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to delete country');
  }
}

