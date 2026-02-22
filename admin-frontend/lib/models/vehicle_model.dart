class Vehicle {
  final int id;
  final String licensePlate;
  final String? make;
  final String? model;
  final int? year;
  final int capacity;
  final int transportTypeId;
  final String transportTypeName;
  final bool isActive;

  Vehicle({
    required this.id,
    required this.licensePlate,
    this.make,
    this.model,
    this.year,
    required this.capacity,
    required this.transportTypeId,
    required this.transportTypeName,
    required this.isActive,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      licensePlate: json['licensePlate'] as String,
      make: json['make'] as String?,
      model: json['model'] as String?,
      year: json['year'] as int?,
      capacity: json['capacity'] as int,
      transportTypeId: json['transportTypeId'] as int,
      transportTypeName: json['transportTypeName'] as String,
      isActive: json['isActive'] as bool,
    );
  }
}

class CreateVehicleRequest {
  final String licensePlate;
  final String? make;
  final String? model;
  final int? year;
  final int capacity;
  final int transportTypeId;

  CreateVehicleRequest({
    required this.licensePlate,
    this.make,
    this.model,
    this.year,
    required this.capacity,
    required this.transportTypeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'licensePlate': licensePlate,
      if (make != null && make!.isNotEmpty) 'make': make,
      if (model != null && model!.isNotEmpty) 'model': model,
      if (year != null) 'year': year,
      'capacity': capacity,
      'transportTypeId': transportTypeId,
    };
  }
}

class UpdateVehicleRequest {
  final String licensePlate;
  final String? make;
  final String? model;
  final int? year;
  final int capacity;
  final int transportTypeId;
  final bool isActive;

  UpdateVehicleRequest({
    required this.licensePlate,
    this.make,
    this.model,
    this.year,
    required this.capacity,
    required this.transportTypeId,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'licensePlate': licensePlate,
      if (make != null && make!.isNotEmpty) 'make': make,
      if (model != null && model!.isNotEmpty) 'model': model,
      if (year != null) 'year': year,
      'capacity': capacity,
      'transportTypeId': transportTypeId,
      'isActive': isActive,
    };
  }
}
