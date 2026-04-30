import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/paged_result.dart';
import '../models/station_model.dart';
import 'auth_service.dart';

class StationService {
  Future<List<Station>> getAll({
    String? search,
    bool? isActive,
  }) async {
    final result = await getPaged(page: 1, pageSize: 100, search: search, isActive: isActive);
    return result.items;
  }

  Future<PagedResult<Station>> getPaged({
    required int page,
    required int pageSize,
    String? search,
    bool? isActive,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/stations/paged')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PagedResult<Station>.fromJson(
          data,
          (json) => Station.fromJson(json),
        );
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
          if (kDebugMode) {
            debugPrint('[StationService] Error parsing response: $e');
            debugPrint('[StationService] Response body: ${response.body}');
          }
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
