import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/transport_line_model.dart';
import 'auth_service.dart';

class RecommendationService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  Future<List<RecommendedLine>> getRecommendedLines({int count = 3}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/recommendations/lines?count=$count'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => RecommendedLine.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recommendations: ${response.statusCode}');
    }
  }

  Future<void> sendFeedback(int transportLineId, bool isUseful) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final requestBody = {
      'transportLineId': transportLineId,
      'isUseful': isUseful,
    };

    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/recommendations/feedback'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to send feedback');
    }
  }

  Future<bool?> getFeedbackStatus(int transportLineId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/recommendations/feedback/$transportLineId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data.containsKey('feedbackStatus')) {
        final feedbackStatus = data['feedbackStatus'];
        return feedbackStatus == null ? null : (feedbackStatus as bool);
      }
      return null;
    } else if (response.statusCode == 204) {
      return null;
    } else {
      throw Exception('Failed to load feedback status: ${response.statusCode}');
    }
  }
}
