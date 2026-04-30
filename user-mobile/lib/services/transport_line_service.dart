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

    final queryParams = <String, String>{
      'page': '1',
      'pageSize': '100',
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final uri = Uri.parse('${AppConfig.resolvedApiBaseUrl}/transportlines/paged')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? const <dynamic>[]);
      return items.map((json) => models.TransportLine.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load transport lines: ${response.statusCode}');
    }
  }

  Future<models.TransportLine?> getById(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/transportlines/$id'),
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

    final uri = Uri.parse('${AppConfig.resolvedApiBaseUrl}/routes/paged').replace(
      queryParameters: {
        'page': '1',
        'pageSize': '1',
        'isActive': 'true',
        'transportLineId': transportLineId.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? const <dynamic>[]);
      if (items.isEmpty) return null;
      return models.Route.fromJson(items.first);
    } else {
      throw Exception('Failed to load routes: ${response.statusCode}');
    }
  }

  Future<models.Route?> getRouteById(int routeId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/routes/$routeId'),
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

    final uri = Uri.parse('${AppConfig.resolvedApiBaseUrl}/schedules/paged').replace(
      queryParameters: {
        'page': '1',
        'pageSize': '100',
        'routeId': routeId.toString(),
        'isActive': 'true',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? const <dynamic>[]);
      return items.map((json) => models.Schedule.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load schedules: ${response.statusCode}');
    }
  }

  Future<List<models.NextDeparture>> getNextDepartures(int routeId, {int count = 3}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConfig.resolvedApiBaseUrl}/routes/$routeId/next-departures')
        .replace(queryParameters: {'count': count.toString()});

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => models.NextDeparture.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load next departures: ${response.statusCode}');
    }
  }
}
