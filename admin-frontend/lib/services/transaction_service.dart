import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/transaction_model.dart';
import 'auth_service.dart';

class TransactionService {
  Future<TransactionMetrics> getMetrics() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/transactions/metrics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TransactionMetrics.fromJson(data);
      } else {
        throw Exception('Failed to load transaction metrics');
      }
    } catch (e) {
      throw Exception('Failed to load transaction metrics: $e');
    }
  }

  Future<List<Transaction>> getAll({
    String? search,
    String? status,
    int? userId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortBy,
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
      if (userId != null) {
        queryParams['userId'] = userId.toString();
      }
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom.toIso8601String();
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo.toIso8601String();
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/transactions')
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
        return data.map((json) => Transaction.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  Future<Transaction?> getById(int id) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/transactions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Transaction.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to load transaction: $e');
    }
  }
}
