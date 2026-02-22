class TransportType {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  TransportType({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
  });

  factory TransportType.fromJson(Map<String, dynamic> json) {
    return TransportType(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class CreateTransportTypeRequest {
  final String name;
  final String? description;

  CreateTransportTypeRequest({
    required this.name,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
    };
  }
}

class UpdateTransportTypeRequest {
  final String name;
  final String? description;
  final bool isActive;

  UpdateTransportTypeRequest({
    required this.name,
    this.description,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'isActive': isActive,
    };
  }
}
