import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/station_model.dart';
import 'auth_service.dart';

class StationService {
  Future<List<Station>> getAll({
    String? search,
    bool? isActive,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      var queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/stations')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Station.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load stations');
      }
    } catch (e) {
      throw Exception('Failed to load stations: $e');
    }
  }

  Future<Station> create(CreateStationRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/stations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return Station.fromJson(data);
        } catch (e) {
          print('[StationService] Error parsing response: $e');
          print('[StationService] Response body: ${response.body}');
          throw Exception('Failed to parse station data from server');
        }
      } else {
        String errorMessage = 'Failed to create station';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message'] as String? ?? errorMessage;
        } catch (_) {
          errorMessage = 'Failed to create station: ${response.statusCode} - ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to create station: $e');
    }
  }

  Future<Station?> update(int id, UpdateStationRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/stations/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Station.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to update station: $e');
    }
  }

  Future<bool> delete(int id) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/stations/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete station: $e');
    }
  }
}
