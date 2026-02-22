import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/transport_line_model.dart';
import 'auth_service.dart';

class TransportLineService {
  Future<List<TransportLine>> getAll({
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

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/transportlines')
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
        return data.map((json) => TransportLine.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load transport lines');
      }
    } catch (e) {
      throw Exception('Failed to load transport lines: $e');
    }
  }

  Future<TransportLine?> getById(int id) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/transportlines/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TransportLine.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to load transport line: $e');
    }
  }

  Future<TransportLine> create(CreateTransportLineRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/transportlines'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TransportLine.fromJson(data);
      } else {
        throw Exception('Failed to create transport line');
      }
    } catch (e) {
      throw Exception('Failed to create transport line: $e');
    }
  }

  Future<TransportLine?> update(int id, UpdateTransportLineRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/transportlines/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TransportLine.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to update transport line: $e');
    }
  }

  Future<bool> delete(int id) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/transportlines/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete transport line: $e');
    }
  }
}
