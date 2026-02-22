class Ticket {
  final int id;
  final String ticketNumber;
  final int userId;
  final String userEmail;
  final int ticketTypeId;
  final String ticketTypeName;
  final int? routeId;
  final String? routeName;
  final int zoneId;
  final String zoneName;
  final double price;
  final DateTime validFrom;
  final DateTime validTo;
  final DateTime purchasedAt;
  final bool isUsed;
  final DateTime? usedAt;
  final String status;
  final bool isActive;

  Ticket({
    required this.id,
    required this.ticketNumber,
    required this.userId,
    required this.userEmail,
    required this.ticketTypeId,
    required this.ticketTypeName,
    this.routeId,
    this.routeName,
    required this.zoneId,
    required this.zoneName,
    required this.price,
    required this.validFrom,
    required this.validTo,
    required this.purchasedAt,
    required this.isUsed,
    this.usedAt,
    required this.status,
    required this.isActive,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      ticketNumber: json['ticketNumber'] as String,
      userId: json['userId'] as int,
      userEmail: json['userEmail'] as String,
      ticketTypeId: json['ticketTypeId'] as int,
      ticketTypeName: json['ticketTypeName'] as String,
      routeId: json['routeId'] as int?,
      routeName: json['routeName'] as String?,
      zoneId: json['zoneId'] as int,
      zoneName: json['zoneName'] as String,
      price: (json['price'] as num).toDouble(),
      validFrom: DateTime.parse(json['validFrom'] as String),
      validTo: DateTime.parse(json['validTo'] as String),
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      isUsed: json['isUsed'] as bool,
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt'] as String) : null,
      status: json['status'] as String,
      isActive: json['isActive'] as bool,
    );
  }
}

class TicketMetrics {
  final int totalTickets;
  final int activeTickets;
  final int usedTicketsThisMonth;
  final int expiredTicketsLast7Days;

  TicketMetrics({
    required this.totalTickets,
    required this.activeTickets,
    required this.usedTicketsThisMonth,
    required this.expiredTicketsLast7Days,
  });

  factory TicketMetrics.fromJson(Map<String, dynamic> json) {
    return TicketMetrics(
      totalTickets: json['totalTickets'] as int,
      activeTickets: json['activeTickets'] as int,
      usedTicketsThisMonth: json['usedTicketsThisMonth'] as int,
      expiredTicketsLast7Days: json['expiredTicketsLast7Days'] as int,
    );
  }
}
