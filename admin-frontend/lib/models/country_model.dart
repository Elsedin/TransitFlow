class Country {
  final int id;
  final String name;
  final String? code;
  final bool isActive;
  final int cityCount;

  Country({
    required this.id,
    required this.name,
    this.code,
    required this.isActive,
    required this.cityCount,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      isActive: json['isActive'] as bool,
      cityCount: json['cityCount'] as int? ?? 0,
    );
  }
}

class CreateCountryRequest {
  final String name;
  final String? code;

  CreateCountryRequest({
    required this.name,
    this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (code != null) 'code': code,
    };
  }
}

class UpdateCountryRequest {
  final String name;
  final String? code;
  final bool isActive;

  UpdateCountryRequest({
    required this.name,
    this.code,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (code != null) 'code': code,
      'isActive': isActive,
    };
  }
}

