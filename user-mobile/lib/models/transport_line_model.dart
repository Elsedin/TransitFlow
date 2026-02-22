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
}

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
}

class RouteStation {
  final int id;
  final int stationId;
  final String stationName;
  final String? stationAddress;
  final int order;

  RouteStation({
    required this.id,
    required this.stationId,
    required this.stationName,
    this.stationAddress,
    required this.order,
  });

  factory RouteStation.fromJson(Map<String, dynamic> json) {
    return RouteStation(
      id: json['id'] as int,
      stationId: json['stationId'] as int,
      stationName: json['stationName'] as String,
      stationAddress: json['stationAddress'] as String?,
      order: json['order'] as int,
    );
  }
}

class Schedule {
  final int id;
  final int routeId;
  final String routeName;
  final String routeOrigin;
  final String routeDestination;
  final int vehicleId;
  final String vehicleLicensePlate;
  final String departureTime;
  final String arrivalTime;
  final int dayOfWeek;
  final String dayOfWeekName;
  final bool isActive;

  Schedule({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.routeOrigin,
    required this.routeDestination,
    required this.vehicleId,
    required this.vehicleLicensePlate,
    required this.departureTime,
    required this.arrivalTime,
    required this.dayOfWeek,
    required this.dayOfWeekName,
    required this.isActive,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as int,
      routeId: json['routeId'] as int,
      routeName: json['routeName'] as String,
      routeOrigin: json['routeOrigin'] as String,
      routeDestination: json['routeDestination'] as String,
      vehicleId: json['vehicleId'] as int,
      vehicleLicensePlate: json['vehicleLicensePlate'] as String,
      departureTime: json['departureTime'] as String,
      arrivalTime: json['arrivalTime'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      dayOfWeekName: json['dayOfWeekName'] as String,
      isActive: json['isActive'] as bool,
    );
  }
}
