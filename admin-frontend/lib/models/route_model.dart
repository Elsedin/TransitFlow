class Route {
  final int id;
  final String name;
  final String origin;
  final String destination;
  final int transportLineId;
  final String transportLineName;
  final String transportLineNumber;
  final double distance;
  final int estimatedDurationMinutes;
  final bool isActive;
  final List<RouteStation> stations;

  Route({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.transportLineId,
    required this.transportLineName,
    required this.transportLineNumber,
    required this.distance,
    required this.estimatedDurationMinutes,
    required this.isActive,
    required this.stations,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] as int,
      name: json['name'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      transportLineId: json['transportLineId'] as int,
      transportLineName: json['transportLineName'] as String,
      transportLineNumber: json['transportLineNumber'] as String,
      distance: (json['distance'] as num).toDouble(),
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int,
      isActive: json['isActive'] as bool,
      stations: (json['stations'] as List<dynamic>?)
          ?.map((s) => RouteStation.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'origin': origin,
      'destination': destination,
      'transportLineId': transportLineId,
      'transportLineName': transportLineName,
      'transportLineNumber': transportLineNumber,
      'distance': distance,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'isActive': isActive,
      'stations': stations.map((s) => s.toJson()).toList(),
    };
  }
}

class RouteStation {
  final int? id;
  final int stationId;
  final String stationName;
  final String? stationAddress;
  final int order;

  RouteStation({
    this.id,
    required this.stationId,
    required this.stationName,
    this.stationAddress,
    required this.order,
  });

  factory RouteStation.fromJson(Map<String, dynamic> json) {
    return RouteStation(
      id: json['id'] as int?,
      stationId: json['stationId'] as int,
      stationName: json['stationName'] as String,
      stationAddress: json['stationAddress'] as String?,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'stationId': stationId,
      'order': order,
    };
  }
}

class CreateRouteRequest {
  final String origin;
  final String destination;
  final int transportLineId;
  final double distance;
  final int estimatedDurationMinutes;
  final List<CreateRouteStationRequest> stations;

  CreateRouteRequest({
    required this.origin,
    required this.destination,
    required this.transportLineId,
    required this.distance,
    required this.estimatedDurationMinutes,
    required this.stations,
  });

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'transportLineId': transportLineId,
      'distance': distance,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'stations': stations.map((s) => s.toJson()).toList(),
    };
  }
}

class CreateRouteStationRequest {
  final int stationId;
  final int order;

  CreateRouteStationRequest({
    required this.stationId,
    required this.order,
  });

  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'order': order,
    };
  }
}

class UpdateRouteRequest {
  final String origin;
  final String destination;
  final int transportLineId;
  final double distance;
  final int estimatedDurationMinutes;
  final bool isActive;
  final List<UpdateRouteStationRequest> stations;

  UpdateRouteRequest({
    required this.origin,
    required this.destination,
    required this.transportLineId,
    required this.distance,
    required this.estimatedDurationMinutes,
    required this.isActive,
    required this.stations,
  });

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'transportLineId': transportLineId,
      'distance': distance,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'isActive': isActive,
      'stations': stations.map((s) => s.toJson()).toList(),
    };
  }
}

class UpdateRouteStationRequest {
  final int? id;
  final int stationId;
  final int order;

  UpdateRouteStationRequest({
    this.id,
    required this.stationId,
    required this.order,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'stationId': stationId,
      'order': order,
    };
  }
}
