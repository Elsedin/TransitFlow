import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/api_error.dart';
import 'auth_service.dart';

class RefundRequestService {
  Future<void> createRefundRequest({
    required int ticketId,
    required String message,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Niste prijavljeni');

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

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Slanje zahtjeva za refund nije uspjelo'));
  }
}
