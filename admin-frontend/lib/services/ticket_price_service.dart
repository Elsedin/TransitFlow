import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ticket_price_model.dart';
import 'auth_service.dart';

class TicketPriceService {
  Future<List<TicketPrice>> getAll({
    int? ticketTypeId,
    int? zoneId,
    bool? isActive,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      var queryParams = <String, String>{};
      if (ticketTypeId != null) {
        queryParams['ticketTypeId'] = ticketTypeId.toString();
      }
      if (zoneId != null) {
        queryParams['zoneId'] = zoneId.toString();
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/ticketprices')
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
        return data.map((json) => TicketPrice.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load ticket prices');
      }
    } catch (e) {
      throw Exception('Failed to load ticket prices: $e');
    }
  }

  Future<TicketPrice> create(CreateTicketPriceRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/ticketprices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketPrice.fromJson(data);
      } else {
        String errorMessage = 'Failed to create ticket price';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message'] as String? ?? errorMessage;
        } catch (_) {
          errorMessage = 'Failed to create ticket price: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to create ticket price: $e');
    }
  }

  Future<TicketPrice?> update(int id, UpdateTicketPriceRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/ticketprices/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketPrice.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to update ticket price: $e');
    }
  }

  Future<bool> delete(int id) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/ticketprices/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete ticket price: $e');
    }
  }
}
