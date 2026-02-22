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

class CreateTicketPriceRequest {
  final int ticketTypeId;
  final int zoneId;
  final double price;
  final DateTime validFrom;
  final DateTime? validTo;

  CreateTicketPriceRequest({
    required this.ticketTypeId,
    required this.zoneId,
    required this.price,
    required this.validFrom,
    this.validTo,
  });

  Map<String, dynamic> toJson() {
    return {
      'ticketTypeId': ticketTypeId,
      'zoneId': zoneId,
      'price': price,
      'validFrom': validFrom.toIso8601String(),
      if (validTo != null) 'validTo': validTo!.toIso8601String(),
    };
  }
}

class UpdateTicketPriceRequest {
  final int ticketTypeId;
  final int zoneId;
  final double price;
  final DateTime validFrom;
  final DateTime? validTo;
  final bool isActive;

  UpdateTicketPriceRequest({
    required this.ticketTypeId,
    required this.zoneId,
    required this.price,
    required this.validFrom,
    this.validTo,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'ticketTypeId': ticketTypeId,
      'zoneId': zoneId,
      'price': price,
      'validFrom': validFrom.toIso8601String(),
      if (validTo != null) 'validTo': validTo!.toIso8601String(),
      'isActive': isActive,
    };
  }
}
