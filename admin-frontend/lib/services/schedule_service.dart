import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/schedule_model.dart';
import 'auth_service.dart';

class ScheduleService {
  Future<List<Schedule>> getAll({
    int? routeId,
    int? vehicleId,
    int? dayOfWeek,
    bool? isActive,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      var queryParams = <String, String>{};
      if (routeId != null) {
        queryParams['routeId'] = routeId.toString();
      }
      if (vehicleId != null) {
        queryParams['vehicleId'] = vehicleId.toString();
      }
      if (dayOfWeek != null) {
        queryParams['dayOfWeek'] = dayOfWeek.toString();
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/schedules')
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
        return data.map((json) => Schedule.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load schedules');
      }
    } catch (e) {
      throw Exception('Failed to load schedules: $e');
    }
  }

  Future<Schedule> create(CreateScheduleRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/schedules'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Schedule.fromJson(data);
      } else {
        String errorMessage = 'Failed to create schedule';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message'] as String? ?? errorMessage;
        } catch (_) {
          errorMessage = 'Failed to create schedule: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to create schedule: $e');
    }
  }

  Future<Schedule?> update(int id, UpdateScheduleRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/schedules/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Schedule.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  Future<bool> delete(int id) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/schedules/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }
}
