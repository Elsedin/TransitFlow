import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/refund_request_model.dart';
import 'auth_service.dart';

class RefundRequestService {
  Exception _buildError(http.Response response, String fallback) {
    final body = response.body;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'];
        if (msg is String && msg.trim().isNotEmpty) {
          return Exception(msg);
        }
      }
    } catch (_) {}
    final compactBody = body.trim().isEmpty ? '' : ' Body: ${body.trim()}';
    return Exception('$fallback (HTTP ${response.statusCode}).$compactBody');
  }

  Future<List<RefundRequest>> getAll({String? status}) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/refundrequests').replace(
      queryParameters: status != null ? {'status': status} : null,
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => RefundRequest.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw _buildError(response, 'Failed to load refund requests');
  }

  Future<RefundRequest> approve(int id, {String? adminNote}) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/refundrequests/$id/approve'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'adminNote': adminNote}),
    );

    if (response.statusCode == 200) {
      return RefundRequest.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw _buildError(response, 'Approve failed');
  }

  Future<RefundRequest> reject(int id, {String? adminNote}) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/refundrequests/$id/reject'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'adminNote': adminNote}),
    );

    if (response.statusCode == 200) {
      return RefundRequest.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw _buildError(response, 'Reject failed');
  }
}

