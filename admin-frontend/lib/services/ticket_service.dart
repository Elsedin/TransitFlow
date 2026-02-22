import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ticket_model.dart';
import 'auth_service.dart';

class TicketService {
  Future<TicketMetrics> getMetrics() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/tickets/metrics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketMetrics.fromJson(data);
      } else {
        throw Exception('Failed to load ticket metrics');
      }
    } catch (e) {
      throw Exception('Failed to load ticket metrics: $e');
    }
  }

  Future<List<Ticket>> getAll({
    String? search,
    String? status,
    int? ticketTypeId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      var queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (ticketTypeId != null) {
        queryParams['ticketTypeId'] = ticketTypeId.toString();
      }
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom.toIso8601String();
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo.toIso8601String();
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/tickets')
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
        return data.map((json) => Ticket.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load tickets');
      }
    } catch (e) {
      throw Exception('Failed to load tickets: $e');
    }
  }

  Future<Ticket?> getById(int id) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/tickets/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Ticket.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to load ticket: $e');
    }
  }
}
