import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ticket_type_model.dart';
import 'auth_service.dart';

class TicketTypeService {
  Future<List<TicketType>> getAll({String? search, bool? isActive}) async {
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

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/tickettypes')
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
        return data.map((json) => TicketType.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load ticket types');
      }
    } catch (e) {
      throw Exception('Failed to load ticket types: $e');
    }
  }

  Future<TicketType> create(CreateTicketTypeRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/tickettypes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketType.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create ticket type');
      }
    } catch (e) {
      throw Exception('Failed to create ticket type: $e');
    }
  }

  Future<TicketType> update(int id, UpdateTicketTypeRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/tickettypes/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketType.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update ticket type');
      }
    } catch (e) {
      throw Exception('Failed to update ticket type: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/tickettypes/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete ticket type');
      }
    } catch (e) {
      throw Exception('Failed to delete ticket type: $e');
    }
  }
}
