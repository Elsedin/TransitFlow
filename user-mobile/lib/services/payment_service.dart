import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/payment_model.dart';
import '../models/subscription_model.dart';
import '../models/ticket_model.dart';
import 'auth_service.dart';

class PaymentService {
  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _ticketPurchaseBody({
    required int ticketTypeId,
    required int routeId,
    required int zoneId,
    required DateTime validFrom,
  }) {
    return {
      'purchaseType': 'ticket',
      'ticketTypeId': ticketTypeId,
      'routeId': routeId,
      'zoneId': zoneId,
      'validFrom': validFrom.toIso8601String(),
      'currency': 'bam',
    };
  }

  Map<String, dynamic> _subscriptionPurchaseBody({required String packageKey}) {
    return {
      'purchaseType': 'subscription',
      'packageKey': packageKey,
      'currency': 'bam',
    };
  }

  Future<PaymentIntentResponse> createStripePaymentIntentForTicket({
    required int ticketTypeId,
    required int routeId,
    required int zoneId,
    required DateTime validFrom,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.resolvedApiBaseUrl}/payments/stripe/create-intent'),
        headers: await _authHeaders(),
        body: jsonEncode(_ticketPurchaseBody(
          ticketTypeId: ticketTypeId,
          routeId: routeId,
          zoneId: zoneId,
          validFrom: validFrom,
        )),
      );

      if (response.statusCode == 200) {
        return PaymentIntentResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['message'] ?? 'Failed to create payment intent');
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  Future<PaymentIntentResponse> createStripePaymentIntentForSubscription({
    required String packageKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.resolvedApiBaseUrl}/payments/stripe/create-intent'),
        headers: await _authHeaders(),
        body: jsonEncode(_subscriptionPurchaseBody(packageKey: packageKey)),
      );

      if (response.statusCode == 200) {
        return PaymentIntentResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['message'] ?? 'Failed to create payment intent');
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  Future<Ticket> finalizeStripeTicketPurchase({
    required String paymentIntentId,
    required int ticketTypeId,
    required int routeId,
    required int zoneId,
    required DateTime validFrom,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/payments/stripe/finalize-ticket'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'paymentIntentId': paymentIntentId,
        'ticketTypeId': ticketTypeId,
        'routeId': routeId,
        'zoneId': zoneId,
        'validFrom': validFrom.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return Ticket.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    final errorData = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(errorData['message'] ?? 'Failed to finalize ticket purchase');
  }

  Future<Subscription> finalizeStripeSubscriptionPurchase({
    required String paymentIntentId,
    required String packageKey,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/payments/stripe/finalize-subscription'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'paymentIntentId': paymentIntentId,
        'packageKey': packageKey,
      }),
    );

    if (response.statusCode == 200) {
      return Subscription.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    final errorData = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(errorData['message'] ?? 'Failed to finalize subscription purchase');
  }

  Future<PayPalOrderResponse> createPayPalOrderForTicket({
    required int ticketTypeId,
    required int routeId,
    required int zoneId,
    required DateTime validFrom,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/payments/paypal/create-order'),
      headers: await _authHeaders(),
      body: jsonEncode(_ticketPurchaseBody(
        ticketTypeId: ticketTypeId,
        routeId: routeId,
        zoneId: zoneId,
        validFrom: validFrom,
      )),
    );

    if (response.statusCode == 200) {
      return PayPalOrderResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    final errorData = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(errorData['message'] ?? 'Failed to create PayPal order');
  }

  Future<PayPalOrderResponse> createPayPalOrderForSubscription({
    required String packageKey,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/payments/paypal/create-order'),
      headers: await _authHeaders(),
      body: jsonEncode(_subscriptionPurchaseBody(packageKey: packageKey)),
    );

    if (response.statusCode == 200) {
      return PayPalOrderResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    final errorData = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(errorData['message'] ?? 'Failed to create PayPal order');
  }

  Future<Ticket> finalizePayPalTicketPurchase({
    required String orderId,
    required int ticketTypeId,
    required int routeId,
    required int zoneId,
    required DateTime validFrom,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/payments/paypal/finalize-ticket'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'orderId': orderId,
        'ticketTypeId': ticketTypeId,
        'routeId': routeId,
        'zoneId': zoneId,
        'validFrom': validFrom.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return Ticket.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    final errorData = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(errorData['message'] ?? 'Failed to finalize ticket purchase');
  }

  Future<Subscription> finalizePayPalSubscriptionPurchase({
    required String orderId,
    required String packageKey,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/payments/paypal/finalize-subscription'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'orderId': orderId,
        'packageKey': packageKey,
      }),
    );

    if (response.statusCode == 200) {
      return Subscription.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    final errorData = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(errorData['message'] ?? 'Failed to finalize subscription purchase');
  }
}
