import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/transport_type_model.dart';
import 'auth_service.dart';

class TransportTypeService {
  Future<List<TransportType>> getAll({String? search, bool? isActive}) async {
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

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/transporttypes')
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
        return data.map((json) => TransportType.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load transport types');
      }
    } catch (e) {
      throw Exception('Failed to load transport types: $e');
    }
  }

  Future<TransportType> create(CreateTransportTypeRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/transporttypes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TransportType.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create transport type');
      }
    } catch (e) {
      throw Exception('Failed to create transport type: $e');
    }
  }

  Future<TransportType> update(int id, UpdateTransportTypeRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/transporttypes/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TransportType.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update transport type');
      }
    } catch (e) {
      throw Exception('Failed to update transport type: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/transporttypes/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete transport type');
      }
    } catch (e) {
      throw Exception('Failed to delete transport type: $e');
    }
  }
}
