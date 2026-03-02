import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ticket_model.dart';
import 'auth_service.dart';

class TicketService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  Future<List<Ticket>> getAll({
    String? search,
    String? status,
    int? ticketTypeId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{};
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
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Ticket.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tickets: ${response.statusCode}');
    }
  }

  Future<Ticket?> getById(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/tickets/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Ticket.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load ticket: ${response.statusCode}');
    }
  }

  Future<List<TicketType>> getTicketTypes({bool? isActive}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{};
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/tickettypes')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => TicketType.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load ticket types: ${response.statusCode}');
    }
  }

  Future<List<TicketPrice>> getTicketPrices({
    int? ticketTypeId,
    int? zoneId,
    bool? isActive,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{};
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
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => TicketPrice.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load ticket prices: ${response.statusCode}');
    }
  }

  Future<Ticket> purchaseTicket({
    required int ticketTypeId,
    required int routeId,
    required int zoneId,
    required DateTime validFrom,
    required DateTime validTo,
    int? transactionId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final requestBody = {
      'ticketTypeId': ticketTypeId,
      'routeId': routeId,
      'zoneId': zoneId,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      if (transactionId != null) 'transactionId': transactionId,
    };

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/tickets/purchase'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Ticket.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to purchase ticket');
    }
  }
}
