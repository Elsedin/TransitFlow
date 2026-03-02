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

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/subscriptions')
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
      Uri.parse('${AppConfig.apiBaseUrl}/subscriptions/$id'),
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
    required String packageName,
    required double price,
    required DateTime startDate,
    required DateTime endDate,
    required String status,
    int? transactionId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final requestBody = {
      'packageName': packageName,
      'price': price,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      if (transactionId != null) 'transactionId': transactionId,
    };

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/subscriptions'),
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
      Uri.parse('${AppConfig.apiBaseUrl}/subscriptions/$id/cancel'),
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

  List<SubscriptionPackage> getAvailablePackages() {
    return [
      SubscriptionPackage(
        name: 'monthly',
        displayName: 'Mjesečna pretplata',
        durationDays: 30,
        price: 45.00,
        benefits: [
          'Neograničen broj vožnji',
          'Sve linije',
          'Automatska obnova',
          'Prioritetna podrška',
        ],
        tag: 'Najpopularnije',
      ),
      SubscriptionPackage(
        name: 'annual',
        displayName: 'Godišnja pretplata',
        durationDays: 365,
        price: 450.00,
        benefits: [
          'Neograničen broj vožnji',
          'Sve linije',
          'Automatska obnova',
          'Prioritetna podrška',
          'Besplatna aplikacija',
        ],
        tag: 'Najisplativije',
        savings: 'Ušteda 90 KM',
      ),
      SubscriptionPackage(
        name: 'student_monthly',
        displayName: 'Studentska mjesečna',
        durationDays: 30,
        price: 30.00,
        benefits: [
          'Neograničen broj vožnji',
          'Sve linije',
          'Vrijedi samo za studente',
        ],
        savings: 'Ušteda 15 KM',
      ),
    ];
  }
}
