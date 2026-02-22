import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/notification_model.dart' as models;
import 'auth_service.dart';

class NotificationService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  Future<List<models.Notification>> getAll({
    int? userId,
    String? type,
    bool? isRead,
    bool? isActive,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/notifications');
    final queryParams = <String, String>{};
    
    if (userId != null) queryParams['userId'] = userId.toString();
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (isRead != null) queryParams['isRead'] = isRead.toString();
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    if (dateFrom != null) queryParams['dateFrom'] = dateFrom.toIso8601String();
    if (dateTo != null) queryParams['dateTo'] = dateTo.toIso8601String();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final finalUri = uri.replace(queryParameters: queryParams);

    final response = await http.get(
      finalUri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => models.Notification.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  }

  Future<models.Notification?> getById(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/notifications/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return models.Notification.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load notification: ${response.statusCode}');
    }
  }

  Future<models.NotificationMetrics> getMetrics() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/notifications/metrics'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return models.NotificationMetrics.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load metrics: ${response.statusCode}');
    }
  }

  Future<models.Notification> create(models.CreateNotificationRequest request) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return models.Notification.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to create notification');
    }
  }

  Future<models.Notification?> update(int id, models.UpdateNotificationRequest request) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/notifications/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return models.Notification.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to update notification');
    }
  }

  Future<bool> delete(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/notifications/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 204;
  }

  Future<bool> markAsRead(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/notifications/$id/mark-read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 200;
  }
}
