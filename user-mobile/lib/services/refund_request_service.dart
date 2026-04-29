import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
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

  Future<void> createRefundRequest({
    required int ticketId,
    required String message,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/refundrequests'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'ticketId': ticketId,
        'message': message,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) return;

    throw _buildError(response, 'Refund request failed');
  }
}

