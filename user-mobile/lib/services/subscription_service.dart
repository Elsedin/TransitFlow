import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/subscription_model.dart';
import 'auth_service.dart';

class SubscriptionService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  Future<List<Subscription>> getAll({
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

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
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Subscription.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load subscriptions: ${response.statusCode}');
    }
  }

  Future<Subscription?> getById(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/subscriptions/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Subscription.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load subscription: ${response.statusCode}');
    }
  }

  Future<Subscription?> getActiveSubscription() async {
    try {
      final subscriptions = await getAll(status: 'active');
      final now = DateTime.now();
      
      final activeSubscriptions = subscriptions
          .where((s) => s.status.toLowerCase() == 'active' && s.endDate.isAfter(now))
          .toList();
      
      return activeSubscriptions.isNotEmpty ? activeSubscriptions.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<Subscription> purchaseSubscription({
    required String packageKey,
    int? transactionId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final requestBody = {
      'packageName': packageKey,
      'price': 0.01,
      'startDate': DateTime.now().toIso8601String(),
      'endDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'status': 'Active',
      if (transactionId != null) 'transactionId': transactionId,
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
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to purchase subscription');
    }
  }

  Future<Subscription> cancelSubscription(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/subscriptions/$id/cancel'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Subscription.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to cancel subscription');
    }
  }

  Future<List<SubscriptionPackage>> fetchAvailablePackages({bool? isActive = true}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

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
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => SubscriptionPackage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load subscription packages: ${response.statusCode}');
    }
  }
}
