class TransportLine {
  final int id;
  final String lineNumber;
  final String name;
  final String origin;
  final String destination;
  final String transportTypeName;
  final bool isActive;

  TransportLine({
    required this.id,
    required this.lineNumber,
    required this.name,
    required this.origin,
    required this.destination,
    required this.transportTypeName,
    required this.isActive,
  });

  factory TransportLine.fromJson(Map<String, dynamic> json) {
    return TransportLine(
      id: json['id'] as int,
      lineNumber: json['lineNumber'] as String,
      name: json['name'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      transportTypeName: json['transportTypeName'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lineNumber': lineNumber,
      'name': name,
      'origin': origin,
      'destination': destination,
      'transportTypeName': transportTypeName,
      'isActive': isActive,
    };
  }
}

class CreateTransportLineRequest {
  final String lineNumber;
  final String name;
  final int transportTypeId;
  final String origin;
  final String destination;
  final double distance;
  final int estimatedDurationMinutes;
  final bool isActive;

  CreateTransportLineRequest({
    required this.lineNumber,
    required this.name,
    required this.transportTypeId,
    required this.origin,
    required this.destination,
    required this.distance,
    required this.estimatedDurationMinutes,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'lineNumber': lineNumber,
      'name': name,
      'transportTypeId': transportTypeId,
      'origin': origin,
      'destination': destination,
      'distance': distance,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'isActive': isActive,
    };
  }
}

class UpdateTransportLineRequest {
  final String lineNumber;
  final String name;
  final int transportTypeId;
  final String origin;
  final String destination;
  final double distance;
  final int estimatedDurationMinutes;
  final bool isActive;

  UpdateTransportLineRequest({
    required this.lineNumber,
    required this.name,
    required this.transportTypeId,
    required this.origin,
    required this.destination,
    required this.distance,
    required this.estimatedDurationMinutes,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'lineNumber': lineNumber,
      'name': name,
      'transportTypeId': transportTypeId,
      'origin': origin,
      'destination': destination,
      'distance': distance,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'isActive': isActive,
    };
  }
}
