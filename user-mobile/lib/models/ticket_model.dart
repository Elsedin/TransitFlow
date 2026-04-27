class Ticket {
  final int id;
  final String publicId;
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
  final String? paymentMethod;

  Ticket({
    required this.id,
    required this.publicId,
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
    this.paymentMethod,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      publicId: json['publicId'] as String,
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
      validFrom: DateTime.parse(json['validFrom'] as String).toLocal(),
      validTo: DateTime.parse(json['validTo'] as String).toLocal(),
      purchasedAt: DateTime.parse(json['purchasedAt'] as String).toLocal(),
      isUsed: json['isUsed'] as bool,
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt'] as String).toLocal() : null,
      status: json['status'] as String,
      isActive: json['isActive'] as bool,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'publicId': publicId,
      'ticketNumber': ticketNumber,
      'userId': userId,
      'userEmail': userEmail,
      'ticketTypeId': ticketTypeId,
      'ticketTypeName': ticketTypeName,
      'routeId': routeId,
      'routeName': routeName,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'price': price,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'purchasedAt': purchasedAt.toIso8601String(),
      'isUsed': isUsed,
      'usedAt': usedAt?.toIso8601String(),
      'status': status,
      'isActive': isActive,
      'paymentMethod': paymentMethod,
    };
  }
}

class TicketType {
  final int id;
  final String name;
  final String? description;
  final int validityDays;
  final bool isActive;

  TicketType({
    required this.id,
    required this.name,
    this.description,
    required this.validityDays,
    required this.isActive,
  });

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      validityDays: json['validityDays'] as int,
      isActive: json['isActive'] as bool,
    );
  }
}

class TicketPrice {
  final int id;
  final int ticketTypeId;
  final String ticketTypeName;
  final int zoneId;
  final String zoneName;
  final double price;
  final int validityDays;
  final String validityDescription;
  final DateTime validFrom;
  final DateTime? validTo;
  final DateTime createdAt;
  final bool isActive;

  TicketPrice({
    required this.id,
    required this.ticketTypeId,
    required this.ticketTypeName,
    required this.zoneId,
    required this.zoneName,
    required this.price,
    required this.validityDays,
    required this.validityDescription,
    required this.validFrom,
    this.validTo,
    required this.createdAt,
    required this.isActive,
  });

  factory TicketPrice.fromJson(Map<String, dynamic> json) {
    return TicketPrice(
      id: json['id'] as int,
      ticketTypeId: json['ticketTypeId'] as int,
      ticketTypeName: json['ticketTypeName'] as String,
      zoneId: json['zoneId'] as int,
      zoneName: json['zoneName'] as String,
      price: (json['price'] as num).toDouble(),
      validityDays: json['validityDays'] as int,
      validityDescription: json['validityDescription'] as String,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validTo: json['validTo'] != null ? DateTime.parse(json['validTo'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool,
    );
  }
}
