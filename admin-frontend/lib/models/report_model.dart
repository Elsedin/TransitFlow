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

class ReportSummaryItem {
  final String label;
  final String value;

  ReportSummaryItem({required this.label, required this.value});

  factory ReportSummaryItem.fromJson(Map<String, dynamic> json) {
    return ReportSummaryItem(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}

class ReportSection {
  final String title;
  final List<String> columns;
  final List<List<String>> rows;

  ReportSection({
    required this.title,
    required this.columns,
    required this.rows,
  });

  factory ReportSection.fromJson(Map<String, dynamic> json) {
    final cols = (json['columns'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList();
    final rows = (json['rows'] as List<dynamic>? ?? const <dynamic>[])
        .map((r) => (r as List<dynamic>).map((c) => c.toString()).toList())
        .toList();

    return ReportSection(
      title: json['title'] as String? ?? '',
      columns: cols,
      rows: rows,
    );
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
  final List<ReportSummaryItem> summaryItems;
  final List<ReportSection> sections;

  Report({
    required this.reportType,
    required this.reportTitle,
    this.dateFrom,
    this.dateTo,
    required this.summary,
    required this.salesByTicketType,
    required this.summaryItems,
    required this.sections,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportType: json['reportType'] as String,
      reportTitle: json['reportTitle'] as String,
      dateFrom: json['dateFrom'] != null ? DateTime.parse(json['dateFrom'] as String) : null,
      dateTo: json['dateTo'] != null ? DateTime.parse(json['dateTo'] as String) : null,
      summary: json['summary'] != null
          ? ReportSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : ReportSummary(totalTickets: 0, totalRevenue: 0, averagePrice: 0, activeUsers: 0),
      salesByTicketType: (json['salesByTicketType'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => ReportByTicketType.fromJson(item as Map<String, dynamic>))
          .toList(),
      summaryItems: (json['summaryItems'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => ReportSummaryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => ReportSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
