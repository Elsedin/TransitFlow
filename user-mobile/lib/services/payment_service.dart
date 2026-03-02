import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/payment_model.dart';
import 'auth_service.dart';

class PaymentService {
  Future<PaymentIntentResponse> createStripePaymentIntent(double amount) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/payments/stripe/create-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': 'bam',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentIntentResponse.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['message'] ?? 'Failed to create payment intent');
      }
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  Future<PaymentResult> confirmStripePayment(String paymentIntentId) async {
    final authService = AuthService();
    
    final isAuthenticated = await authService.isAuthenticated();
    if (!isAuthenticated) {
      throw Exception('Sesija je istekla. Molimo prijavite se ponovo.');
    }

    final token = await authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesija je istekla. Molimo prijavite se ponovo.');
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/payments/stripe/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentResult.fromJson(data);
      } else if (response.statusCode == 401) {
        await authService.logout();
        throw Exception('Sesija je istekla. Molimo prijavite se ponovo.');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['message'] ?? 'Failed to confirm payment');
      }
    } catch (e) {
      if (e.toString().contains('Not authenticated') || e.toString().contains('401')) {
        await authService.logout();
        throw Exception('Sesija je istekla. Molimo prijavite se ponovo.');
      }
      rethrow;
    }
  }

  Future<PayPalOrderResponse> createPayPalOrder(double amount) async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/payments/paypal/create-order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'currency': 'bam',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PayPalOrderResponse.fromJson(data);
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['message'] ?? 'Failed to create PayPal order');
    }
  }

  Future<PaymentResult> capturePayPalOrder(String orderId) async {
    final authService = AuthService();
    
    final isAuthenticated = await authService.isAuthenticated();
    if (!isAuthenticated) {
      throw Exception('Sesija je istekla. Molimo prijavite se ponovo.');
    }

    final token = await authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesija je istekla. Molimo prijavite se ponovo.');
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/payments/paypal/capture'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'orderId': orderId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentResult.fromJson(data);
      } else if (response.statusCode == 401) {
        await authService.logout();
        throw Exception('Sesija je istekla. Molimo prijavite se ponovo.');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['message'] ?? 'Failed to capture PayPal order');
      }
    } catch (e) {
      if (e.toString().contains('Not authenticated') || e.toString().contains('401')) {
        await authService.logout();
        throw Exception('Sesija je istekla. Molimo prijavite se ponovo.');
      }
      rethrow;
    }
  }
}
