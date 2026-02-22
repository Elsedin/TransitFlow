class ReportRequest {
  final String reportType;
  final String? period;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? transportLineId;
  final int? ticketTypeId;

  ReportRequest({
    this.reportType = 'ticket_sales',
    this.period,
    this.dateFrom,
    this.dateTo,
    this.transportLineId,
    this.ticketTypeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportType': reportType,
      if (period != null && period!.isNotEmpty) 'period': period,
      if (dateFrom != null) 'dateFrom': dateFrom!.toIso8601String(),
      if (dateTo != null) 'dateTo': dateTo!.toIso8601String(),
      if (transportLineId != null) 'transportLineId': transportLineId,
      if (ticketTypeId != null) 'ticketTypeId': ticketTypeId,
    };
  }
}

class ReportSummary {
  final int totalTickets;
  final double totalRevenue;
  final double averagePrice;
  final int activeUsers;

  ReportSummary({
    required this.totalTickets,
    required this.totalRevenue,
    required this.averagePrice,
    required this.activeUsers,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalTickets: json['totalTickets'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      averagePrice: (json['averagePrice'] as num).toDouble(),
      activeUsers: json['activeUsers'] as int,
    );
  }
}

class ReportByTicketType {
  final String ticketTypeName;
  final int count;
  final double revenue;

  ReportByTicketType({
    required this.ticketTypeName,
    required this.count,
    required this.revenue,
  });

  factory ReportByTicketType.fromJson(Map<String, dynamic> json) {
    return ReportByTicketType(
      ticketTypeName: json['ticketTypeName'] as String,
      count: json['count'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class Report {
  final String reportType;
  final String reportTitle;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ReportSummary summary;
  final List<ReportByTicketType> salesByTicketType;

  Report({
    required this.reportType,
    required this.reportTitle,
    this.dateFrom,
    this.dateTo,
    required this.summary,
    required this.salesByTicketType,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportType: json['reportType'] as String,
      reportTitle: json['reportTitle'] as String,
      dateFrom: json['dateFrom'] != null ? DateTime.parse(json['dateFrom'] as String) : null,
      dateTo: json['dateTo'] != null ? DateTime.parse(json['dateTo'] as String) : null,
      summary: ReportSummary.fromJson(json['summary'] as Map<String, dynamic>),
      salesByTicketType: (json['salesByTicketType'] as List<dynamic>)
          .map((item) => ReportByTicketType.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
