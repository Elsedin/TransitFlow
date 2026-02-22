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

class CreateTicketTypeRequest {
  final String name;
  final String? description;
  final int validityDays;

  CreateTicketTypeRequest({
    required this.name,
    this.description,
    required this.validityDays,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'validityDays': validityDays,
    };
  }
}

class UpdateTicketTypeRequest {
  final String name;
  final String? description;
  final int validityDays;
  final bool isActive;

  UpdateTicketTypeRequest({
    required this.name,
    this.description,
    required this.validityDays,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'validityDays': validityDays,
      'isActive': isActive,
    };
  }
}
