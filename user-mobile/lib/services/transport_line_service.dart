import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/transport_line_model.dart' as models;
import 'auth_service.dart';

class TransportLineService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  Future<List<models.TransportLine>> getAll({
    String? search,
    bool? isActive,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{};
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
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => models.TransportLine.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load transport lines: ${response.statusCode}');
    }
  }

  Future<models.TransportLine?> getById(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/transportlines/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return models.TransportLine.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load transport line: ${response.statusCode}');
    }
  }

  Future<models.Route?> getRouteByLineId(int transportLineId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/routes?isActive=true'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final routes = data.map((json) => models.Route.fromJson(json)).toList();
      return routes.firstWhere(
        (r) => r.transportLineId == transportLineId,
        orElse: () => routes.isNotEmpty ? routes.first : throw StateError('No routes found'),
      );
    } else {
      throw Exception('Failed to load routes: ${response.statusCode}');
    }
  }

  Future<models.Route?> getRouteById(int routeId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/routes/$routeId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return models.Route.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load route: ${response.statusCode}');
    }
  }

  Future<List<models.Schedule>> getSchedulesByRouteId(int routeId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/schedules?routeId=$routeId&isActive=true'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => models.Schedule.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load schedules: ${response.statusCode}');
    }
  }
}
