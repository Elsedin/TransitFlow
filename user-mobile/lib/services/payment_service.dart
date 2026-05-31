import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/payment_model.dart';
import '../models/subscription_model.dart';
import '../models/ticket_model.dart';
import '../utils/api_error.dart';
import 'auth_service.dart';

class PaymentService {
  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Niste prijavljeni');
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
    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Kreiranje plaćanja nije uspjelo'));
  }

  Future<PaymentIntentResponse> createStripePaymentIntentForSubscription({
    required String packageKey,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.resolvedApiBaseUrl}/payments/stripe/create-intent'),
      headers: await _authHeaders(),
      body: jsonEncode(_subscriptionPurchaseBody(packageKey: packageKey)),
    );

    if (response.statusCode == 200) {
      return PaymentIntentResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Kreiranje plaćanja nije uspjelo'));
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
    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Finalizacija kupovine karte nije uspjela'));
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
    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Finalizacija kupovine pretplate nije uspjela'));
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
    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Kreiranje PayPal narudžbe nije uspjelo'));
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
    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Kreiranje PayPal narudžbe nije uspjelo'));
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
    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Finalizacija kupovine karte nije uspjela'));
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
    throw Exception(ApiError.fromResponseBody(response.body, fallback: 'Finalizacija kupovine pretplate nije uspjela'));
  }
}
