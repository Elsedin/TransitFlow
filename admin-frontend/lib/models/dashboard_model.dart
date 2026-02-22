import 'package:flutter/material.dart';

class DashboardMetrics {
  final int totalUsers;
  final double totalUsersChange;
  final int soldTicketsToday;
  final double soldTicketsChange;
  final double monthlyRevenue;
  final double monthlyRevenueChange;
  final int activeLines;
  final List<TicketSalesData> ticketSalesData;
  final List<TicketTypeDistribution> ticketTypeDistribution;
  final List<PopularLine> popularLines;

  DashboardMetrics({
    required this.totalUsers,
    required this.totalUsersChange,
    required this.soldTicketsToday,
    required this.soldTicketsChange,
    required this.monthlyRevenue,
    required this.monthlyRevenueChange,
    required this.activeLines,
    required this.ticketSalesData,
    required this.ticketTypeDistribution,
    required this.popularLines,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalUsers: json['totalUsers'] as int,
      totalUsersChange: (json['totalUsersChange'] as num).toDouble(),
      soldTicketsToday: json['soldTicketsToday'] as int,
      soldTicketsChange: (json['soldTicketsChange'] as num).toDouble(),
      monthlyRevenue: (json['monthlyRevenue'] as num).toDouble(),
      monthlyRevenueChange: (json['monthlyRevenueChange'] as num).toDouble(),
      activeLines: json['activeLines'] as int,
      ticketSalesData: (json['ticketSalesData'] as List)
          .map((e) => TicketSalesData.fromJson(e as Map<String, dynamic>))
          .toList(),
      ticketTypeDistribution: (json['ticketTypeDistribution'] as List)
          .map((e) => TicketTypeDistribution.fromJson(e as Map<String, dynamic>))
          .toList(),
      popularLines: (json['popularLines'] as List)
          .map((e) => PopularLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalUsersChange': totalUsersChange,
      'soldTicketsToday': soldTicketsToday,
      'soldTicketsChange': soldTicketsChange,
      'monthlyRevenue': monthlyRevenue,
      'monthlyRevenueChange': monthlyRevenueChange,
      'activeLines': activeLines,
      'ticketSalesData': ticketSalesData.map((e) => e.toJson()).toList(),
      'ticketTypeDistribution': ticketTypeDistribution.map((e) => e.toJson()).toList(),
      'popularLines': popularLines.map((e) => e.toJson()).toList(),
    };
  }
}

class TicketSalesData {
  final DateTime date;
  final int sales;

  TicketSalesData({
    required this.date,
    required this.sales,
  });

  factory TicketSalesData.fromJson(Map<String, dynamic> json) {
    return TicketSalesData(
      date: DateTime.parse(json['date'] as String),
      sales: json['sales'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'sales': sales,
    };
  }
}

class TicketTypeDistribution {
  final String type;
  final int count;
  final int colorValue;

  TicketTypeDistribution({
    required this.type,
    required this.count,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  factory TicketTypeDistribution.fromJson(Map<String, dynamic> json) {
    return TicketTypeDistribution(
      type: json['type'] as String,
      count: json['count'] as int,
      colorValue: json['colorValue'] as int? ?? json['color'] as int? ?? 0xFF000000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'count': count,
      'colorValue': colorValue,
    };
  }
}

class PopularLine {
  final String lineNumber;
  final String origin;
  final String destination;
  final int ticketCount;
  final double revenue;

  PopularLine({
    required this.lineNumber,
    required this.origin,
    required this.destination,
    required this.ticketCount,
    required this.revenue,
  });

  factory PopularLine.fromJson(Map<String, dynamic> json) {
    return PopularLine(
      lineNumber: json['lineNumber'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      ticketCount: json['ticketCount'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lineNumber': lineNumber,
      'origin': origin,
      'destination': destination,
      'ticketCount': ticketCount,
      'revenue': revenue,
    };
  }
}
