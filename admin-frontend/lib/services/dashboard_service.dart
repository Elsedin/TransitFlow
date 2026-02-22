import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/dashboard_model.dart';
import 'auth_service.dart';

class DashboardService {
  Future<DashboardMetrics> getMetrics() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final metricsResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/dashboard/metrics'),
        headers: headers,
      );

      if (metricsResponse.statusCode != 200) {
        throw Exception('Failed to load metrics');
      }

      final metricsData = jsonDecode(metricsResponse.body) as Map<String, dynamic>;

      final ticketSalesResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/dashboard/ticket-sales?days=30'),
        headers: headers,
      );

      final ticketTypeResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/dashboard/ticket-type-distribution'),
        headers: headers,
      );

      final popularLinesResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/dashboard/popular-lines?top=5'),
        headers: headers,
      );

      List<TicketSalesData> ticketSalesData = [];
      if (ticketSalesResponse.statusCode == 200) {
        final salesList = jsonDecode(ticketSalesResponse.body) as List;
        ticketSalesData = salesList.map((e) {
          final item = e as Map<String, dynamic>;
          return TicketSalesData(
            date: DateTime.parse(item['date'] as String),
            sales: item['count'] as int,
          );
        }).toList();
      }

      List<TicketTypeDistribution> ticketTypeDistribution = [];
      if (ticketTypeResponse.statusCode == 200) {
        final typeList = jsonDecode(ticketTypeResponse.body) as List;
        final colors = [
          Colors.orange[300]!,
          Colors.orange[400]!,
          Colors.orange[500]!,
          Colors.orange[600]!,
          Colors.orange[700]!,
          Colors.orange[800]!,
        ];
        int colorIndex = 0;
        ticketTypeDistribution = typeList.map((e) {
          final item = e as Map<String, dynamic>;
          final color = colors[colorIndex % colors.length];
          colorIndex++;
          return TicketTypeDistribution(
            type: item['ticketTypeName'] as String,
            count: item['count'] as int,
            colorValue: color.value,
          );
        }).toList();
      }

      List<PopularLine> popularLines = [];
      if (popularLinesResponse.statusCode == 200) {
        final linesList = jsonDecode(popularLinesResponse.body) as List;
        popularLines = linesList.map((e) {
          final item = e as Map<String, dynamic>;
          final route = item['route'] as String;
          final parts = route.split(' - ');
          return PopularLine(
            lineNumber: item['lineNumber'] as String,
            origin: parts.isNotEmpty ? parts[0] : '',
            destination: parts.length > 1 ? parts[1] : '',
            ticketCount: item['ticketCount'] as int,
            revenue: (item['revenue'] as num).toDouble(),
          );
        }).toList();
      }

      return DashboardMetrics(
        totalUsers: metricsData['totalUsers'] as int,
        totalUsersChange: 0.0,
        soldTicketsToday: metricsData['totalTicketsSold'] as int,
        soldTicketsChange: 0.0,
        monthlyRevenue: (metricsData['totalRevenue'] as num).toDouble(),
        monthlyRevenueChange: 0.0,
        activeLines: metricsData['activeRoutes'] as int,
        ticketSalesData: ticketSalesData,
        ticketTypeDistribution: ticketTypeDistribution,
        popularLines: popularLines,
      );
    } catch (e) {
      throw Exception('Failed to load dashboard data: $e');
    }
  }
}
