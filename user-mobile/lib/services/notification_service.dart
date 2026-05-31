import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/notification_model.dart' as models;
import '../utils/api_error.dart';
import 'auth_service.dart';

class NotificationService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  Future<List<models.Notification>> getAll({bool? isRead}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Niste prijavljeni');

    final queryParams = <String, String>{
      'page': '1',
      'pageSize': '100',
    };
    if (isRead != null) {
      queryParams['isRead'] = isRead.toString();
    }

    final uri = Uri.parse('${AppConfig.resolvedApiBaseUrl}/notifications/my')
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
      return items.map((json) => models.Notification.fromJson(json)).toList();
    }

    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Učitavanje notifikacija nije uspjelo'));
  }

  Future<int> getUnreadCount() async {
    final token = await _getToken();
    if (token == null) throw Exception('Niste prijavljeni');

    final response = await http.get(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/notifications/my/unread-count'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as int;
    }

    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Učitavanje broja notifikacija nije uspjelo'));
  }

  Future<bool> markAsRead(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Niste prijavljeni');

    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/notifications/$id/mark-read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Označavanje notifikacije nije uspjelo'));
  }
}
