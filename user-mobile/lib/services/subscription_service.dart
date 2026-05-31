import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/subscription_model.dart';
import '../utils/api_error.dart';
import 'auth_service.dart';

class SubscriptionService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  List<dynamic> _extractItems(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final items = decoded['items'];
      if (items is List) return items;
    }
    throw Exception('Neočekivani format odgovora');
  }

  Future<List<Subscription>> getAll({
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Niste prijavljeni');

    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (dateFrom != null) {
      queryParams['dateFrom'] = dateFrom.toIso8601String();
    }
    if (dateTo != null) {
      queryParams['dateTo'] = dateTo.toIso8601String();
    }

    final uri = Uri.parse('${AppConfig.resolvedApiBaseUrl}/subscriptions')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final items = _extractItems(decoded);
      return items.map((json) => Subscription.fromJson(json)).toList();
    }

    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Učitavanje pretplata nije uspjelo'));
  }

  Future<Subscription?> getById(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Niste prijavljeni');

    final response = await http.get(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/subscriptions/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Subscription.fromJson(json.decode(response.body));
    }
    if (response.statusCode == 404) {
      return null;
    }

    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Učitavanje pretplate nije uspjelo'));
  }

  Future<Subscription?> getActiveSubscription() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${AppConfig.resolvedApiBaseUrl}/subscriptions/active'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Subscription.fromJson(json.decode(response.body));
      }
      if (response.statusCode == 404) {
        return null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Subscription> purchaseSubscription({
    required String packageKey,
    int? transactionId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Niste prijavljeni');

    final requestBody = {
      'packageName': packageKey,
      'price': 0.01,
      'startDate': DateTime.now().toIso8601String(),
      'endDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'status': 'Active',
      ...?(transactionId == null ? null : {'transactionId': transactionId}),
    };

    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/subscriptions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Subscription.fromJson(json.decode(response.body));
    }

    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Kupovina pretplate nije uspjela'));
  }

  Future<Subscription> cancelSubscription(int id, {required String reason}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Niste prijavljeni');

    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/subscriptions/$id/cancel'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'reason': reason.trim()}),
    );

    if (response.statusCode == 200) {
      return Subscription.fromJson(json.decode(response.body));
    }

    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Otkazivanje pretplate nije uspjelo'));
  }

  Future<List<SubscriptionPackage>> fetchAvailablePackages({bool? isActive = true}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Niste prijavljeni');

    final queryParams = <String, String>{};
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final uri = Uri.parse('${AppConfig.resolvedApiBaseUrl}/subscription-packages')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final items = _extractItems(decoded);
      return items.map((json) => SubscriptionPackage.fromJson(json)).toList();
    }

    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Učitavanje paketa pretplata nije uspjelo'));
  }
}
