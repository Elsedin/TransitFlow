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

class CreateScheduleRequest {
  final int routeId;
  final int vehicleId;
  final String departureTime;
  final String arrivalTime;
  final int dayOfWeek;

  CreateScheduleRequest({
    required this.routeId,
    required this.vehicleId,
    required this.departureTime,
    required this.arrivalTime,
    required this.dayOfWeek,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'vehicleId': vehicleId,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'dayOfWeek': dayOfWeek,
    };
  }
}

class UpdateScheduleRequest {
  final int routeId;
  final int vehicleId;
  final String departureTime;
  final String arrivalTime;
  final int dayOfWeek;
  final bool isActive;

  UpdateScheduleRequest({
    required this.routeId,
    required this.vehicleId,
    required this.departureTime,
    required this.arrivalTime,
    required this.dayOfWeek,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'vehicleId': vehicleId,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'dayOfWeek': dayOfWeek,
      'isActive': isActive,
    };
  }
}
