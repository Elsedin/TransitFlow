import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/report_model.dart';
import 'auth_service.dart';

class ReportService {
  Future<Report> generateReport(ReportRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/reports/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Report.fromJson(data);
      } else {
        String errorMessage = 'Failed to generate report';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message'] as String? ?? errorMessage;
        } catch (_) {
          errorMessage = 'Failed to generate report: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }

  Future<Uint8List> downloadTicketSalesPdf(ReportRequest request) async {
    return _downloadPdf('${AppConfig.apiBaseUrl}/reports/ticket-sales/pdf', request);
  }

  Future<Uint8List> downloadRefundRequestsPdf(ReportRequest request) async {
    return _downloadPdf('${AppConfig.apiBaseUrl}/reports/refund-requests/pdf', request);
  }

  Future<Uint8List> _downloadPdf(String url, ReportRequest request) async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    String errorMessage = 'Failed to download PDF';
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = errorData['message'] as String? ?? errorMessage;
    } catch (_) {
      errorMessage = 'Failed to download PDF: ${response.statusCode}';
    }
    throw Exception(errorMessage);
  }
}
